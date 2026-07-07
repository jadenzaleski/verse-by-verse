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
        let configuration = URLSessionConfiguration.default
        // Fail fast: verse text is small and the app must stay usable offline,
        // so a hung request shouldn't stall the UI for the system default 60s.
        configuration.timeoutIntervalForRequest = 15
        session = URLSession(configuration: configuration)
        log.debug("URLSession initialized")
    }

    /// Lowest-level request.
    func raw(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.httpStatus(0)
        }

        return (data, http)
    }

    /// Decode helper so decoding logic lives in one place.
    func decode<T: Decodable>(
        data: Data,
        response: HTTPURLResponse,
        as _: T.Type,
    ) throws -> APIResponse<T> {
        log.debug("Response code: \(response.statusCode)")

        let decodedBody = try JSONDecoder.vbv.decode(T.self, from: data)

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

// MARK: - Shared JSON coding strategy

extension JSONDecoder {
    /// The app-wide decoder: ISO-8601 dates with or without fractional seconds.
    static var vbv: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = DateFormatters.iso8601Fractional.date(from: string) {
                return date
            }
            if let date = DateFormatters.iso8601.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO8601 date: \(string)",
            )
        }
        return decoder
    }
}

extension JSONEncoder {
    /// The app-wide encoder: ISO-8601 dates with fractional seconds.
    static var vbv: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(DateFormatters.iso8601Fractional.string(from: date))
        }
        return encoder
    }
}

private enum DateFormatters {
    static let iso8601Fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
