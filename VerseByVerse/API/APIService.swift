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
    private let log = AppLog.category("APIService")

    func fetch<T: Codable>(
        key: String,
        expiresIn: TimeInterval? = nil,
        request: URLRequest,
    ) async throws -> APIResponse<T> {
        log.debug("Fetch:\nurl: \(request)\nkey: \(key)")

        // Cache
        if let cached = cache.get(key, decode: T.self) {
            log.debug("Found key \"\(key)\" in cache")
            return cached
        }

        // Network
        log.debug("Did not find key \"\(key)\" in cache, making network request")
        let (data, response) = try await network.raw(request)

        let apiResponse = try network.decode(
            data: data,
            response: response,
            as: T.self,
        )

        log.debug("Adding key \"\(key)\" to cache")
        cache.set(
            key: key,
            data: data,
            statusCode: apiResponse.statusCode,
            expiresIn: expiresIn,
        )

        return apiResponse
    }

    func getHealth() async throws -> Bool {
        log.debug("getHealth called")
        do {
            let response: APIResponse<HealthCheckResponse> = try await fetch(
                key: "health",
                expiresIn: 60,
                request: APIEndpoint.healthcheck.request,
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
