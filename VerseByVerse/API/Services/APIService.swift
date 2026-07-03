//
//  APIService.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

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
        lookInCache: Bool? = nil,
        saveToCache: Bool? = nil,
        attemptRefresh: Bool = true,
    ) async throws -> APIResponse<T> {
        let cacheKey = endpoint.cacheIdentifier
        let request = endpoint.request
        let isGet = endpoint.method == "GET"

        let defaultLook = isGet
        let defaultSave = isGet
        let effectiveLookInCache = lookInCache ?? defaultLook
        let effectiveSaveToCache = saveToCache ?? defaultSave

        log.debug("""
        Fetch:
        - url: \(request)
        - key: \(cacheKey)
        - debugKey: \(endpoint.debugIdentifier)
        - ttl: \(String(describing: endpoint.ttl))
        - lookInCache: \(effectiveLookInCache) \(lookInCache != nil ? "(override)" : "(default)")
        - saveToCache: \(effectiveSaveToCache) \(saveToCache != nil ? "(override)" : "(default)")
        - attemptRefresh: \(attemptRefresh)
        """)

        // Cache
        if effectiveLookInCache, let cached = cache.get(cacheKey, decode: T.self) {
            log.debug("Found key \"\(cacheKey)\" in cache")
            return cached
        } else {
            log.debug("\"\(cacheKey)\" not found in cache, or cache ignored.")
        }

        do {
            // Network
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

            if effectiveSaveToCache {
                log.debug("Adding key \"\(cacheKey)\" to cache")
                cache.set(
                    key: cacheKey,
                    response: apiResponse,
                    ttl: endpoint.ttl,
                )
            } else {
                log.debug("\"\(cacheKey)\" not being saved to cache")
            }

            for invalidated in endpoint.invalidates {
                cache.remove(invalidated.cacheIdentifier)
                log.debug("Invalidated cache key for \(invalidated.debugIdentifier)")
            }

            return apiResponse
        } catch {
            throw mapError(error)
        }
    }

    /// Maps an arbitrary thrown error to an `APIError`, logging along the way.
    private func mapError(_ error: Error) -> APIError {
        // Preserve APIError thrown above
        if let apiError = error as? APIError { return apiError }

        // Map explicit Task cancellation
        if error is CancellationError {
            return .cancelled
        }

        // Map common error types
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

    /// Performs a request that returns no body (e.g. 204 No Content).
    func fetchVoid(endpoint: APIEndpoint, attemptRefresh: Bool = true) async throws {
        let request = endpoint.request
        log.debug("FetchVoid: \(endpoint.debugIdentifier)")
        let (data, response) = try await performRequestWithOptionalRefresh(for: request, attemptRefresh: attemptRefresh)
        if !(200 ... 299).contains(response.statusCode) {
            let message = parseServerErrorMessage(from: data)
            throw APIError.http(statusCode: response.statusCode, message: message, data: data)
        }
        for invalidated in endpoint.invalidates {
            cache.remove(invalidated.cacheIdentifier)
            log.debug("Invalidated cache key for \(invalidated.debugIdentifier)")
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
