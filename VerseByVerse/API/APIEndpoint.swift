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
        case .fetchUser(let id): return "/users/\(id)"
        case .listPlants: return "/plants"
        case .login: return "/login"
        case .healthcheck: return "/health"
        }
    }

    var method: String {
        switch self {
        case .login: return "POST"
        default: return "GET"
        }
    }

    var body: Data? {
        switch self {
        case .login(let email, let password):
            return try? JSONEncoder().encode(["email": email, "password": password])
        default:
            return nil
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
