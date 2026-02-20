//
//  APIEndpoint.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

enum APIEndpoint {
    case postLogin(email: String, password: String)
    case postRegister(firstName: String, lastName: String, email: String, password: String)
    case postRefresh(accessToken: String, refreshToken: String)
    case getUser
    case getHealth

    var path: String {
        switch self {
        case .postLogin: "/auth/redis/login"
        case .postRegister: "/auth/register"
        case .postRefresh: "/auth/refresh"
        case .getUser: "/user/me"
        case .getHealth: "/health"
        }
    }

    var method: String {
        switch self {
        case .postLogin: "POST"
        case .postRegister: "POST"
        case .postRefresh: "POST"
        default: "GET"
        }
    }

    var contentType: String {
        switch self {
        case .postLogin: "application/x-www-form-urlencoded"
        default: "application/json"
        }
    }

    var token: String? {
        switch self {
        case .getUser:
            (try? KeychainManager.getAccessToken()) ?? nil
        default:
            nil
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case let .postRefresh(accessToken, refreshToken):
            [
                URLQueryItem(name: "access_token", value: accessToken),
                URLQueryItem(name: "refresh_token", value: refreshToken),
            ]
        default:
            nil
        }
    }

    var body: Data? {
        switch self {
        case let .postLogin(email, password):
            let parameters = "username=\(email)&password=\(password)"
            return parameters.data(using: .utf8)
        case let .postRegister(firstName, lastName, email, password):
            let json: [String: Any] = [
                "email": email,
                "password": password,
                "first_name": firstName,
                "last_name": lastName,
            ]
            return try? JSONSerialization.data(withJSONObject: json, options: [])
        default:
            return nil
        }
    }

    var request: URLRequest {
        let log = AppLog.category("APIEndpoint.request")
        let base = APIConfig.shared.baseURL.appendingPathComponent(path)

        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        let finalURL = components?.url ?? base
        var req = URLRequest(url: finalURL)
        req.httpMethod = method
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")

        if token != nil {
            req.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = body
            log.debug("HTTP body set: \(String(data: body, encoding: .utf8) ?? "nil")")
        } else {
            log.debug("No HTTP body for request")
        }

        return req
    }
}
