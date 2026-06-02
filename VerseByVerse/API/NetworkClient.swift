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
        if let jsonString = String(data: data, encoding: .utf8) {
            log.trace("JSON response body:\n\(jsonString)")
            log.debug("Response Code: \(response.statusCode)")
        }

        let decoder = JSONDecoder()

        // Use ISO8601 with fractional seconds
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = isoFormatter.date(from: string) {
                return date
            }
            // Fallback to plain ISO8601 without fractional seconds if needed
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            if let date = fallback.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO8601 date: \(string)",
            )
        }

        let decodedBody = try decoder.decode(T.self, from: data)

        return APIResponse(
            statusCode: response.statusCode,
            body: decodedBody,
        )
    }
}

struct APIResponse<T: Codable>: Codable {
    let statusCode: Int
    let body: T

    enum CodingKeys: String, CodingKey {
        case statusCode
        case body
    }
}

enum NetworkError: Error {
    case httpStatus(Int)
}
