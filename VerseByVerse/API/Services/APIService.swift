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
    ) async throws -> APIResponse<T> {
        let cacheKey = endpoint.cacheIdentifier

        if lookInCache, let cached = cache.get(cacheKey, decode: T.self) {
            log.debug("Cache hit: \(endpoint.debugIdentifier)")
            return cached
        }

        log.debug("Fetching: \(endpoint.debugIdentifier)")

        do {
            let (data, response) = try await network.raw(endpoint.request)

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

            if saveToCache {
                cache.set(key: cacheKey, response: apiResponse, ttl: endpoint.ttl)
            }

            reportReachability(endpoint: endpoint, reachable: true)
            return apiResponse
        } catch {
            let mapped = mapError(error)
            if let reachable = reachability(for: mapped) {
                reportReachability(endpoint: endpoint, reachable: reachable)
            }
            throw mapped
        }
    }

    /// Whether an error tells us anything about server reachability.
    /// `.network` means we couldn't reach the host at all; `.http`/
    /// `.decoding` mean something answered, which still confirms the
    /// server's up. `.cancelled`/`.unknown` say nothing either way — the
    /// request was aborted or the failure is unclassified, so no signal.
    private func reachability(for error: APIError) -> Bool? {
        switch error {
        case .network: false
        case .http, .decoding: true
        case .cancelled, .unknown: nil
        }
    }

    /// Feeds real request outcomes to `NetworkMonitor` so it can tell
    /// "offline" apart from "server unreachable" without polling blindly.
    /// Skips `.getHealth` — that's the monitor's own probe request, not
    /// app-driven traffic, and reporting it back in would just be noise.
    private func reportReachability(endpoint: APIEndpoint, reachable: Bool) {
        guard endpoint != .getHealth else { return }
        Task { @MainActor in
            if reachable {
                NetworkMonitor.shared.reportSuccess()
            } else {
                NetworkMonitor.shared.reportFailure()
            }
        }
    }

    /// Maps an arbitrary thrown error to an `APIError`, logging along the way.
    private func mapError(_ error: Error) -> APIError {
        if let apiError = error as? APIError { return apiError }

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

        if let text = String(data: data, encoding: .utf8) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }
}
