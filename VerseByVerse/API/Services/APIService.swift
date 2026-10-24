//
//  APIService.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

/// Fetch-and-decode layer over the VBV Bible API, with a two-level
/// (memory + disk) response cache.
final class APIService {
    static let shared = APIService()

    private let cache = Cache.shared
    private let network = NetworkClient.shared
    let log = AppLog.category("APIService")

    /// Fetches and decodes an API response.
    /// - Returns: A decoded `APIResponse<T>` on success.
    /// - Throws: `APIError` for HTTP, network, decoding, cancellation, or unknown errors.
    func fetch<T: Codable>(
        endpoint: APIEndpoint,
        lookInCache: Bool = true,
        saveToCache: Bool = true,
        isCacheable: (T) -> Bool = { _ in true },
    ) async throws -> APIResponse<T> {
        let cacheKey = endpoint.cacheIdentifier

        if lookInCache, let cached = cache.get(cacheKey, decode: T.self), isCacheable(cached.body) {
            log.debug("Cache hit: \(endpoint.debugIdentifier)")
            return cached
        }

        log.debug("Fetching: \(endpoint.debugIdentifier)")

        do {
            var (data, response) = try await send(endpoint)

            // The session token expired or was rejected: drop it and retry
            // once — `send` refreshes it (or goes out unattested).
            if response.statusCode == 401, endpoint.sendsAttestToken,
               ["ATTEST_TOKEN_EXPIRED", "ATTEST_TOKEN_INVALID"].contains(parseServerErrorMessage(from: data))
            {
                log.info("Session token rejected on \(endpoint.debugIdentifier); refreshing and retrying once")
                AppAttestClient.shared.invalidateToken()
                (data, response) = try await send(endpoint)
            }

            if response.statusCode == 403, parseServerErrorMessage(from: data) == "ATTESTATION_REQUIRED" {
                log.warning("Server requires App Attest for \(endpoint.debugIdentifier)")
                throw APIError.attestationRequired
            }

            if response.statusCode == 429 {
                let retryAfter = APIError.retryAfter(from: response)
                log.error("Rate limited on \(endpoint.debugIdentifier); retry after \(retryAfter)s")
                throw APIError.rateLimited(retryAfter: retryAfter)
            }

            if !(200 ... 299).contains(response.statusCode) {
                log.error("API returned code \(response.statusCode) for \(endpoint.debugIdentifier)")
                let message = parseServerErrorMessage(from: data)
                throw APIError.http(statusCode: response.statusCode, message: message, data: data)
            }

            let apiResponse = try network.decode(
                data: data,
                response: response,
                as: T.self,
            )

            if saveToCache, isCacheable(apiResponse.body) {
                cache.set(key: cacheKey, response: apiResponse, ttl: endpoint.ttl)
            }

            reportReachability(endpoint: endpoint, status: .online)
            return apiResponse
        } catch {
            let mapped = mapError(error)
            if let status = NetworkMonitor.classify(mapped) {
                reportReachability(endpoint: endpoint, status: status)
            }
            throw mapped
        }
    }

    /// Sends the endpoint's request, attaching the App Attest session token
    /// when the endpoint is gated and one is available. No token (Simulator,
    /// unsupported device, attestation still pending or failing) just means
    /// the request goes out unattested. Never log the header.
    private func send(_ endpoint: APIEndpoint) async throws -> (Data, HTTPURLResponse) {
        var request = endpoint.request
        if endpoint.sendsAttestToken, let token = await AppAttestClient.shared.token() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return try await network.raw(request)
    }

    /// Feeds real request outcomes to `NetworkMonitor` so it can tell
    /// "offline" apart from "server unreachable" without polling blindly.
    /// Skips `.getHealth` — that's the monitor's own probe request, not
    /// app-driven traffic, and reporting it back in would just be noise.
    private func reportReachability(endpoint: APIEndpoint, status: NetworkMonitor.Status) {
        guard endpoint != .getHealth else { return }
        Task { @MainActor in
            NetworkMonitor.shared.report(status)
        }
    }

    /// Maps an arbitrary thrown error to an `APIError`, logging along the way.
    private func mapError(_ error: Error) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        }

        if error is CancellationError {
            return .cancelled
        }

        if let urlError = error as? URLError {
            if urlError.code == .cancelled {
                return .cancelled
            } else {
                log.error("Network error: \(urlError)")
                return .network(underlying: urlError)
            }
        }

        if let decodingError = error as? DecodingError {
            log.error("Decoding error: \(decodingError)")
            return .decoding(underlying: decodingError)
        }

        if case let NetworkError.httpStatus(statusCode) = error {
            log.error("Network error: non-HTTP response (status \(statusCode))")
            return .http(statusCode: statusCode, message: nil, data: nil)
        }

        log.error("Unknown error: \(error)")
        return .unknown(underlying: error)
    }

    /// Extracts a human-readable message from a server error payload.
    /// The API uses FastAPI's `{"detail": ...}` shape.
    private func parseServerErrorMessage(from data: Data) -> String? {
        struct ErrorEnvelope: Decodable {
            let detail: String?
        }

        if let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data),
           let detail = envelope.detail, !detail.isEmpty
        {
            return detail
        }

        // Short plain-text bodies are shown as-is. Markup (e.g. Cloudflare's
        // 502 page, which replaces our JSON error) or anything long isn't a
        // message — fall back to APIError's status-code text instead.
        if let text = String(data: data, encoding: .utf8) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !trimmed.hasPrefix("<"), trimmed.count <= 200 {
                return trimmed
            }
        }
        return nil
    }
}
