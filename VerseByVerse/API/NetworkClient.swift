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
        // Without this, URLSession would also keep its
        // own copy of every response in Library/Caches/…/Cache.db.
        configuration.urlCache = nil
        session = URLSession(configuration: configuration)
        // Builds before this change wrote responses into the shared URL
        // cache; nothing in the app uses it, so purge any leftovers once per
        // launch, off the main thread (it's disk I/O).
        // Remove before launch.
        Task.detached(priority: .utility) {
            URLCache.shared.removeAllCachedResponses()
        }
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

nonisolated struct APIResponse<T: Codable>: Codable {
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

nonisolated extension JSONDecoder {
    /// The app-wide decoder: ISO-8601 dates with or without fractional seconds.
    static var vbv: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = try? DateFormatters.iso8601Fractional.parse(string) {
                return date
            }
            if let date = try? DateFormatters.iso8601.parse(string) {
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

nonisolated extension JSONEncoder {
    /// The app-wide encoder: ISO-8601 dates with fractional seconds.
    static var vbv: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(DateFormatters.fractionalString(from: date))
        }
        return encoder
    }
}

/// `Date.ISO8601FormatStyle` is a `Sendable` value type (unlike
/// `ISO8601DateFormatter`), so these can be shared statics under Swift 6.
/// Both format and parse in UTC with a trailing `Z`.
private nonisolated enum DateFormatters {
    static let iso8601Fractional = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    static let iso8601 = Date.ISO8601FormatStyle()

    /// `2026-01-02T12:00:00.123Z`, rounded to the nearest millisecond.
    ///
    /// `ISO8601FormatStyle(includingFractionalSeconds: true)` *truncates* the
    /// fraction, and a millisecond that isn't exactly representable as a
    /// `Double` (most of them) lands just below its value and truncates a
    /// millisecond low, so a decode-then-encode round trip would drift. Counting
    /// whole milliseconds as integers first keeps encoding stable, and only the
    /// whole-second part goes through the format style.
    static func fractionalString(from date: Date) -> String {
        let totalMilliseconds = Int64((date.timeIntervalSince1970 * 1000).rounded())
        var seconds = totalMilliseconds / 1000
        var milliseconds = totalMilliseconds % 1000
        if milliseconds < 0 {
            // Before 1970: keep the fraction positive, counting from the earlier second.
            milliseconds += 1000
            seconds -= 1
        }
        let wholeSeconds = Date(timeIntervalSince1970: Double(seconds)).formatted(iso8601)
        let digits = String(milliseconds)
        let fraction = String(repeating: "0", count: 3 - digits.count) + digits
        // `wholeSeconds` ends in "Z"; the fraction goes before it.
        return wholeSeconds.dropLast() + "." + fraction + "Z"
    }
}
