//
//  APIService.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

final class APIService {
    static let shared = APIService()

    private let cache = CacheService.shared
    private let network = NetworkClient.shared
    private let log = AppLog.category("APIService")

    func fetch<T: Codable>(
        key: String,
        expiresIn: TimeInterval? = nil,
        request: URLRequest
    ) async throws -> APIResponse<T> {
        log.debug("Fetch:\nurl: \(request)\nkey: \(key)")

        // 1. Cache
        if let cached: APIResponse<T> = cache.get(key) {
            log.debug("Found key \"\(key)\" in cache")
            return cached
        }

        // 2. Network
        log.debug("Did not find key \"\(key)\" in cache")
        let result: APIResponse = try await network.send(request, decode: T.self)

        // 3. Store
        log.debug("Adding key \"\(key)\" to cache")
        cache.set(key, value: result, expiresIn: expiresIn)

        return result
    }

    func getHealth() async throws -> Bool {
        log.debug("getHealth called")
        do {
            let response: APIResponse<HealthCheckResponse> = try await fetch(
                key: "health",
                expiresIn: 60,
                request: APIEndpoint.healthcheck.request
            )

            return response.statusCode == 200 &&
            response.body.status == "ok" &&
            response.body.db == "ok"
        } catch {
            return false
        }
    }
}

// https://app.quicktype.io
struct HealthCheckResponse: Codable {
    let status: String
    // swiftlint:disable:next identifier_name
    let db: String
}
