//
//  APIService.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

/// A standardized error for all API calls.
/// Contains HTTP status code when available and a human-readable message when possible.
enum APIError: Error, LocalizedError {
    case http(statusCode: Int, message: String?, data: Data?)
    case network(underlying: URLError)
    case decoding(underlying: DecodingError)
    case cancelled
    case unknown(underlying: Error)

    /// A human-readable description suitable for UI.
    var errorDescription: String? {
        switch self {
        case let .http(statusCode, message, _):
            message ?? "Server returned status code \(statusCode)."
        case let .network(underlying):
            underlying.localizedDescription
        case let .decoding(underlying):
            "Failed to decode response: \(underlying.localizedDescription)"
        case .cancelled:
            "Request was cancelled."
        case let .unknown(underlying):
            underlying.localizedDescription
        }
    }

    /// The HTTP status code, if this is an HTTP error.
    var statusCode: Int? {
        if case let .http(statusCode, _, _) = self { return statusCode }
        return nil
    }
}

final class APIService {
    static let shared = APIService()

    private let cache = Cache.shared
    private let network = NetworkClient.shared
    let log = AppLog.category("APIService")

    /// Fetches and decodes an API response.
    /// - Returns: A decoded `APIResponse<T>` on success.
    /// - Throws: `APIError` for HTTP, network, decoding, cancellation, or unknown errors.
    func fetch<T: Codable>(
        key: String,
        expiresIn: TimeInterval? = nil,
        request: URLRequest,
        lookInCache: Bool = false,
        saveToCache: Bool = true,
        attemptRefresh: Bool = false,
    ) async throws -> APIResponse<T> {
        log.debug("Fetch:\n- url: \(request)\n- key: \(key)\n"
            + "- expiresIn: \(String(describing: expiresIn))\n"
            + "- lookInCache: \(lookInCache)\n- saveToCache: \(saveToCache)\n"
            + "- attemptRefresh: \(attemptRefresh)")

        // Cache
        if lookInCache, let cached = cache.get(key, decode: T.self) {
            log.debug("Found key \"\(key)\" in cache")
            return cached
        } else {
            log.debug("\"\(key)\" not found in cache, or cache ignored.")
        }

        do {
            // Network
            log.debug("Making network request")
            let (data, response) = try await performRequestWithOptionalRefresh(for: request,
                                                                               attemptRefresh: attemptRefresh)

            if !(200 ... 299).contains(response.statusCode) {
                log.error("API returned code: \(response.statusCode)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    log.debug("API error response body:\n\(jsonString)")
                }
                let message = parseServerErrorMessage(from: data)
                throw APIError.http(statusCode: response.statusCode, message: message, data: data)
            }

            let apiResponse = try network.decode(
                data: data,
                response: response,
                as: T.self,
            )

            if saveToCache {
                log.debug("Adding key \"\(key)\" to cache")
                cache.set(
                    key: key,
                    response: apiResponse,
                    expiresIn: expiresIn,
                )
            } else {
                log.debug("\"\(key)\" not being saved to cache")
            }

            return apiResponse
        } catch {
            // Preserve APIError thrown above
            if let apiError = error as? APIError { throw apiError }

            // Map explicit Task cancellation
            if error is CancellationError {
                throw APIError.cancelled
            }

            // Map common error types
            if let urlError = error as? URLError {
                if urlError.code == .cancelled {
                    throw APIError.cancelled
                } else {
                    log.error("Network error: \(urlError)")
                    throw APIError.network(underlying: urlError)
                }
            }

            if let decodingError = error as? DecodingError {
                log.error("Decoding error: \(decodingError)")
                throw APIError.decoding(underlying: decodingError)
            }

            log.error("Unknown error: \(error)")
            throw APIError.unknown(underlying: error)
        }
    }

    private func performRequestWithOptionalRefresh(
        for request: URLRequest,
        attemptRefresh: Bool,
    ) async throws -> (Data, HTTPURLResponse) {
        var (data, response) = try await network.raw(request)

        guard attemptRefresh, response.statusCode == 401 else {
            return (data, response)
        }

        log.warning("API returned 401, attempting to refresh access token")

        let newAccessToken = try await refreshTokensOrSignalUnauthorized()

        var retried = request
        retried.setValue("Bearer \(newAccessToken)", forHTTPHeaderField: "Authorization")

        (data, response) = try await network.raw(retried)

        if response.statusCode == 401 {
            NotificationCenter.default.post(name: .unauthorized, object: nil)
        }

        return (data, response)
    }

    private func refreshTokensOrSignalUnauthorized() async throws -> String {
        let accessToken = try KeychainManager.getAccessToken()
        let refreshToken = try KeychainManager.getRefreshToken()

        // Ensure tokens exist
        if accessToken == nil || refreshToken == nil {
            NotificationCenter.default.post(name: .unauthorized, object: nil)
            throw APIError.http(statusCode: 401,
                                message: "No access token or refresh token",
                                data: Data())
        }

        do {
            let refreshed = try await postRefresh(accessToken: accessToken!, refreshToken: refreshToken!)
            try KeychainManager.saveAccessToken(refreshed.accessToken)
            try KeychainManager.saveRefreshToken(refreshed.refreshToken)
            log.info("Tokens have been refreshed.")
            return refreshed.accessToken
        } catch {
            // ANY error during refresh means our session is likely dead or irrecoverable
            log.error("Refresh failed: \(error.localizedDescription). Signaling unauthorized.")
            NotificationCenter.default.post(name: .unauthorized, object: nil)
            throw error
        }
    }

    /// Attempts to extract a human-readable message from a server error payload.
    private func parseServerErrorMessage(from data: Data) -> String? {
        // Try common JSON shapes first
        struct ErrorEnvelope: Decodable {
            let message: String?
            let error: String?
            let detail: String?
            let errors: [String]?
        }

        if let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) {
            if let msg = envelope.message, !msg.isEmpty { return msg }
            if let err = envelope.error, !err.isEmpty { return err }
            if let detail = envelope.detail, !detail.isEmpty { return detail }
            if let list = envelope.errors, let first = list.first, !first.isEmpty { return first }
        }

        // Fallback to plain text if present
        if let text = String(data: data, encoding: .utf8) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }
}
