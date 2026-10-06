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
        case .emptySelection:
            "No verse text was returned. Try again later."
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
