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
        default:
            nil
        }
    }

    /// How long to wait before retrying a 429, from its `Retry-After` header.
    /// The API sends whole seconds and its window is 60s, so the value is
    /// clamped to 1...60; a missing or non-numeric header (including the
    /// HTTP-date form, which the API never sends) falls back to a short default.
    static func retryAfter(from response: HTTPURLResponse) -> TimeInterval {
        let fallback: TimeInterval = 5
        guard let raw = response.value(forHTTPHeaderField: "Retry-After"),
              let seconds = Int(raw.trimmingCharacters(in: .whitespaces))
        else {
            return fallback
        }
        return TimeInterval(min(max(seconds, 1), 60))
    }
}
