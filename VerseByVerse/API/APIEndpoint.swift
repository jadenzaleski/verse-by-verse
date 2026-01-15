//
//  APIEndpoint.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

enum APIEndpoint {
    case fetchUser(id: String)
    case listPlants
    case login(email: String, password: String)
    case healthcheck

    var path: String {
        switch self {
        case let .fetchUser(id): "/users/\(id)"
        case .listPlants: "/plants"
        case .login: "/login"
        case .healthcheck: "/health"
        }
    }

    var method: String {
        switch self {
        case .login: "POST"
        default: "GET"
        }
    }

    var body: Data? {
        switch self {
        case let .login(email, password):
            try? JSONEncoder().encode(["email": email, "password": password])
        default:
            nil
        }
    }

    var request: URLRequest {
        let url = APIConfig.shared.baseURL.appendingPathComponent(path)

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return req
    }
}
