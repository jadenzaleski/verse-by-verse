//
//  NetworkClient.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

final class NetworkClient {
    static let shared = NetworkClient()
    private let session: URLSession
    private let log = AppLog.category("NetworkClient")

    private init() {
        session = URLSession(configuration: .default)
        log.debug("URLSession initialized")
    }

    func send<T: Decodable>(_ request: URLRequest, decode _: T.Type) async throws -> APIResponse<T> {
        let (data, response) = try await raw(request)

        let apiResponse = try decode(
            data: data,
            response: response,
            as: T.self,
        )

        if !(200 ..< 300).contains(apiResponse.statusCode) {
            throw NetworkError.httpStatus(apiResponse.statusCode)
        }

        return apiResponse
    }

    /// Lowest-level request (used for disk caching)
    func raw(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.httpStatus(0)
        }

        return (data, http)
    }

    /// Decode helper so decoding logic lives in one place
    func decode<T: Decodable>(
        data: Data,
        response: HTTPURLResponse,
        as _: T.Type,
    ) throws -> APIResponse<T> {
        let decodedBody = try JSONDecoder().decode(T.self, from: data)

        return APIResponse(
            statusCode: response.statusCode,
            body: decodedBody,
        )
    }
}

struct APIResponse<T: Decodable> {
    let statusCode: Int
    let body: T
}

enum NetworkError: Error {
    case httpStatus(Int)
}
