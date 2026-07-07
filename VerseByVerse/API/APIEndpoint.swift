//
//  APIEndpoint.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import CryptoKit
import Foundation

/// The VBV API surface: a Bible-text proxy plus a health check.
/// All endpoints are GETs authenticated with a static app key
/// (`X-App-Key`, injected via xcconfig — see Secrets.example.xcconfig).
enum APIEndpoint: Hashable {
    case getHealth
    case getBibleBooks
    case getBibleTranslations
    case getBibleSelection(translation: String, startReference: String, endReference: String?, strip: Bool)

    var path: String {
        switch self {
        case .getHealth: "/health"
        case .getBibleBooks: "/static/bible_books_array.min.json"
        case .getBibleTranslations: "/bible/translations"
        case .getBibleSelection: "/bible"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case let .getBibleSelection(translation, startReference, endReference, strip):
            [
                URLQueryItem(name: "translation", value: translation),
                URLQueryItem(name: "start", value: startReference),
                URLQueryItem(name: "end", value: endReference),
                URLQueryItem(name: "strip_formatting", value: String(strip)),
            ]
        default:
            nil
        }
    }

    /// Time in seconds before a cached response expires. Verse text is
    /// immutable, so Bible responses cache long.
    var ttl: TimeInterval? {
        switch self {
        case .getHealth:
            nil
        case .getBibleBooks, .getBibleTranslations, .getBibleSelection:
            30 * 24 * 60 * 60 // 30 days
        }
    }

    var debugIdentifier: String {
        var parts: [String] = ["GET", path]
        if let items = queryItems, !items.isEmpty {
            let query = items
                .sorted { $0.name < $1.name }
                .map { "\($0.name)=\($0.value ?? "")" }
                .joined(separator: "&")
            parts.append(query)
        }
        return parts.joined(separator: " | ")
    }

    var cacheIdentifier: String {
        Data(debugIdentifier.utf8).sha256Hex
    }

    var request: URLRequest {
        let base = AppFunctions.apiBaseURL.appendingPathComponent(path)

        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        var req = URLRequest(url: components?.url ?? base)
        req.httpMethod = "GET"
        // Never log the key (see AppLog's no-secrets rule).
        if let key = AppFunctions.appAPIKey {
            req.setValue(key, forHTTPHeaderField: "X-App-Key")
        }
        return req
    }
}

private extension Data {
    var sha256Hex: String {
        SHA256.hash(data: self).map { String(format: "%02x", $0) }.joined()
    }
}
