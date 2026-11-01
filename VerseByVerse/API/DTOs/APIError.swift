//
//  APIError.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

/// A standardized error for all API calls.
/// Contains HTTP status code when available and a human-readable message when possible.
enum APIError: Error, LocalizedError {
    case http(statusCode: Int, message: String?, data: Data?)
    case network(underlying: URLError)
    case decoding(underlying: DecodingError)
    case cancelled
    case emptySelection
    /// HTTP 429: the per-IP limit was hit. `retryAfter` is the server's
    /// `Retry-After`, in seconds (see ``retryAfter(from:)``).
    case rateLimited(retryAfter: TimeInterval)
    /// HTTP 403 `ATTESTATION_REQUIRED`: a licensed translation the server only
    /// serves to an App Attest–verified app (never the Simulator).
    case attestationRequired
    /// HTTP 400 `PASSAGE_TOO_LONG`: the range is over the translation's
    /// `passageLimit` (the ESV). `message` is the server's sentence without
    /// the code.
    case passageTooLong(message: String?)
    /// HTTP 503 with a `Retry-After` longer than a minute: the upstream
    /// provider throttled the server (e.g. Crossway's hourly/daily ESV
    /// limits), so retrying automatically would only spin.
    case temporarilyUnavailable(message: String?)
    case unknown(underlying: Error)

    /// A human-readable description suitable for UI.
    var errorDescription: String? {
        switch self {
        case let .http(statusCode, message, _):
            message ?? ((500 ... 599).contains(statusCode)
                ? "The server ran into a problem (\(statusCode)). Try again in a moment."
                : "Server returned status code \(statusCode).")
        case let .network(underlying):
            underlying.localizedDescription
        case let .decoding(underlying):
            "Failed to decode response: \(underlying.localizedDescription)"
        case .cancelled:
            "Request was cancelled."
        case .emptySelection:
            "No verse text was returned. Try again later."
        case .rateLimited:
            "The server is busy. Try again in a moment."
        case .attestationRequired:
            "This translation is only available in the App Store and TestFlight versions of the app."
        case let .passageTooLong(message):
            message ?? "This passage is too long for this translation. Try a shorter range."
        case let .temporarilyUnavailable(message):
            message ?? "This translation is temporarily unavailable. Try again later."
        case let .unknown(underlying):
            underlying.localizedDescription
        }
    }

    /// The HTTP status code, if this is an HTTP error.
    var statusCode: Int? {
        switch self {
        case let .http(statusCode, _, _):
            statusCode
        case .rateLimited:
            429
        case .attestationRequired:
            403
        case .passageTooLong:
            400
        case .temporarilyUnavailable:
            503
        default:
            nil
        }
    }

    /// How long to wait before retrying a 429, from its `Retry-After` header.
    /// The API sends whole seconds and its window is 60s, so the value is
    /// clamped to 1...60; a missing or non-numeric header (including the
    /// HTTP-date form, which the API never sends) falls back to a short default.
    static func retryAfter(from response: HTTPURLResponse) -> TimeInterval {
        guard let seconds = retryAfterSeconds(from: response) else { return 5 }
        return TimeInterval(min(max(seconds, 1), 60))
    }

    /// The raw `Retry-After` in whole seconds, or `nil` when it's missing or
    /// not numeric.
    static func retryAfterSeconds(from response: HTTPURLResponse) -> Int? {
        response.value(forHTTPHeaderField: "Retry-After")
            .flatMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }

    /// Longest `Retry-After` on a 503 that's still retried automatically;
    /// past it the upstream limit is hourly/daily and the user retries by hand.
    static let maxAutomaticRetryAfter = 60

    /// Maps a non-2xx response to its error. `detail` is the server's
    /// `{"detail": ...}` message, if any.
    static func from(response: HTTPURLResponse, detail: String?, data: Data?) -> APIError {
        switch response.statusCode {
        case 403 where detail == "ATTESTATION_REQUIRED":
            return .attestationRequired
        case 429:
            return .rateLimited(retryAfter: retryAfter(from: response))
        case 400 where detail?.hasPrefix(passageTooLongCode) == true:
            return .passageTooLong(message: detail.flatMap(stripPassageTooLongCode))
        case 503:
            guard let seconds = retryAfterSeconds(from: response) else { break }
            if seconds <= maxAutomaticRetryAfter {
                return .rateLimited(retryAfter: TimeInterval(max(seconds, 1)))
            }
            return .temporarilyUnavailable(message: detail)
        default:
            break
        }
        return .http(statusCode: response.statusCode, message: detail, data: data)
    }

    private static let passageTooLongCode = "PASSAGE_TOO_LONG"

    /// "PASSAGE_TOO_LONG: the ESV can…" → "The ESV can…"; `nil` if nothing's left.
    private static func stripPassageTooLongCode(_ detail: String) -> String? {
        let rest = detail.dropFirst(passageTooLongCode.count)
            .drop { $0 == ":" || $0 == " " }
        guard let first = rest.first else { return nil }
        return first.uppercased() + rest.dropFirst()
    }
}
