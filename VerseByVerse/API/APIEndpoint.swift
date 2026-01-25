//
//  APIEndpoint.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

enum APIEndpoint {
    case login(email: String, password: String)
    case healthcheck

    var path: String {
        switch self {
        case .login: "/auth/redis/login"
        case .healthcheck: "/health"
        }
    }

    var method: String {
        switch self {
        case .login: "POST"
        default: "GET"
        }
    }

    var contentType: String {
        switch self {
        case .login: "application/x-www-form-urlencoded"
        default: "application/json"
        }
    }

    var body: Data? {
        switch self {
        case let .login(email, password):
            let parameters = "username=\(email)&password=\(password)"
            return parameters.data(using: .utf8)
        default:
            return nil
        }
    }

    var request: URLRequest {
        let log = AppLog.category("APIEndpoint.request")
        let url = APIConfig.shared.baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")

        if let body {
            req.httpBody = body
            log.debug("HTTP body set: \(String(data: body, encoding: .utf8) ?? "nil")")
        } else {
            log.debug("No HTTP body for request")
        }

        return req
    }
}
