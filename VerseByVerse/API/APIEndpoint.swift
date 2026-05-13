//
//  APIEndpoint.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

enum APIEndpoint {
    // Login
    case postLogin(email: String, password: String)
    case postRegister(firstName: String, lastName: String, email: String, password: String)
    case postRefresh(accessToken: String, refreshToken: String)
    // User
    case getUser
    case patchUser(firstName: String?, lastName: String?, email: String?, password: String?)
    // Bible
    case getBibleBooks
    case getBibleTranslations
    case getBiblePassage(translation: String, startReference: String, endReference: String?, strip: Bool)
    // Passages
    case getPassage(id: Int)
    case patchPassage(id: Int, book: String?,
                      startChapter: Int?,
                      endChapter: Int?,
                      startVerse: Int?,
                      endVerse: Int?,
                      translation: String?,
                      lastPracticed: Date?)
    case deletePassage(id: Int)
    case postPassage(book: String,
                     startChapter: Int,
                     endChapter: Int,
                     startVerse: Int,
                     endVerse: Int,
                     translation: String,
                     lastPracticed: Date?)
    case getUserPassageList
    /// Other
    case getHealth

    var path: String {
        switch self {
        case .postLogin: "/auth/redis/login"
        case .postRegister: "/auth/register"
        case .postRefresh: "/auth/refresh"
        case .getUser: "/user/me"
        case .patchUser: "/user/me"
        case .getHealth: "/health"
        case .getBibleBooks: "/static/bible_books_array.min.json"
        case .getBibleTranslations: "/bible/translations"
        case .getBiblePassage: "/bible"
        case .getPassage: "/passage"
        case .patchPassage: "/passage"
        case .deletePassage: "/passage"
        case .postPassage: "/passage"
        case .getUserPassageList: "/passage/list/me"
        }
    }

    var method: String {
        switch self {
        case .postLogin: "POST"
        case .postRegister: "POST"
        case .postRefresh: "POST"
        case .patchUser: "PATCH"
        case .patchPassage: "PATCH"
        case .deletePassage: "DELETE"
        case .postPassage: "POST"
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
        case .postLogin, .postRegister, .postRefresh, .getHealth, .getBibleBooks:
            nil
        default:
            (try? KeychainManager.getAccessToken()) ?? nil
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case let .postRefresh(accessToken, refreshToken):
            [
                URLQueryItem(name: "access_token", value: accessToken),
                URLQueryItem(name: "refresh_token", value: refreshToken),
            ]
        case let .getBiblePassage(translation, startReference, endReference, strip):
            [
                URLQueryItem(name: "translation", value: translation),
                URLQueryItem(name: "start", value: startReference),
                URLQueryItem(name: "end", value: endReference),
                URLQueryItem(name: "strip_formatting", value: String(strip)),
            ]
        case let .getPassage(id):
            [
                URLQueryItem(name: "id", value: String(id)),
            ]
        case let .patchPassage(id, book, startChapter, endChapter, startVerse, endVerse, translation, lastPracticed):
            [
                URLQueryItem(name: "id", value: String(id)),
            ]
        case let .deletePassage(id):
            [
                URLQueryItem(name: "id", value: String(id)),
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
        case let .patchUser(firstName, lastName, email, password):
            var json: [String: Any] = [:]
            // if values are not null, add to body
            if firstName != nil {
                json["first_name"] = firstName
            }
            if lastName != nil {
                json["last_name"] = lastName
            }
            if email != nil {
                json["email"] = email
            }
            if password != nil {
                json["password"] = password
            }
            return try? JSONSerialization.data(withJSONObject: json, options: [])
        case let .postPassage(book, startChapter, endChapter, startVerse, endVerse, translation, lastPracticed):
            var json: [String: Any] = [:]
            json["book"] = book
            json["start_chapter"] = startChapter
            json["end_chapter"] = endChapter
            json["start_verse"] = startVerse
            json["end_verse"] = endVerse
            json["translation"] = translation
            if lastPracticed != nil {
                json["last_practiced"] = lastPracticed
            }
            return try? JSONSerialization.data(withJSONObject: json, options: [])
        case let .patchPassage(id,
                               book,
                               startChapter,
                               endChapter,
                               startVerse,
                               endVerse,
                               translation,
                               lastPracticed):
            var json: [String: Any] = [:]
            if book != nil {
                json["book"] = book
            }
            if startChapter != nil {
                json["start_chapter"] = startChapter
            }
            if endChapter != nil {
                json["end_chapter"] = endChapter
            }
            if startVerse != nil {
                json["start_verse"] = startVerse
            }
            if endVerse != nil {
                json["end_verse"] = endVerse
            }
            if translation != nil {
                json["translation"] = translation
            }
            if lastPracticed != nil {
                json["last_practiced"] = lastPracticed
            }
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
