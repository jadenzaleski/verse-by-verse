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
    case getBibleSelection(translation: String, startReference: String, endReference: String?, strip: Bool)
    // Passages
    case getPassage(id: Int)
    case patchPassage(id: Int,
                      book: String?,
                      startChapter: Int?,
                      endChapter: Int?,
                      startVerse: Int?,
                      endVerse: Int?,
                      translation: String?)
    case deletePassage(id: Int)
    case createPassage(book: String,
                       startChapter: Int,
                       endChapter: Int,
                       startVerse: Int,
                       endVerse: Int,
                       translation: String)
    case getMyPassages
    // Study Sets
    case getMyStudySets
    case getStudySet(id: Int)
    case createStudySet(name: String, description: String?, positionSeed: Int, colorSeed: Int, theme: String, passageIds: [Int]?)
    case patchStudySet(id: Int, name: String?, description: String?, positionSeed: Int?, colorSeed: Int?, theme: String?)
    case deleteStudySet(id: Int)
    case addPassageToStudySet(studySetId: Int, passageId: Int)
    case removePassageFromStudySet(studySetId: Int, passageId: Int)
    // Practice Sessions
    case getMyPracticeSessions
    case startPracticeSession(passageId: Int)
    case completePracticeSession(id: Int, score: Double)
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
        case .getBibleSelection: "/bible"
        case let .getPassage(id): "/passage/\(id)"
        case let .patchPassage(id, _, _, _, _, _, _): "/passage/\(id)"
        case let .deletePassage(id): "/passage/\(id)"
        case .createPassage: "/passage/"
        case .getMyPassages: "/passage/list/me"
        case .getMyStudySets: "/study-set/list/me"
        case let .getStudySet(id): "/study-set/\(id)"
        case .createStudySet: "/study-set/"
        case let .patchStudySet(id, _, _, _, _, _): "/study-set/\(id)"
        case let .deleteStudySet(id): "/study-set/\(id)"
        case let .addPassageToStudySet(sid, pid): "/study-set/\(sid)/passage/\(pid)"
        case let .removePassageFromStudySet(sid, pid): "/study-set/\(sid)/passage/\(pid)"
        case .getMyPracticeSessions: "/practice-session/list/me"
        case .startPracticeSession: "/practice-session/start"
        case let .completePracticeSession(id, _): "/practice-session/\(id)/complete"
        }
    }

    var method: String {
        switch self {
        case .postLogin, .postRegister, .postRefresh, .createPassage, .createStudySet, .addPassageToStudySet, .startPracticeSession, .completePracticeSession: "POST"
        case .patchUser, .patchPassage, .patchStudySet: "PATCH"
        case .deletePassage, .deleteStudySet, .removePassageFromStudySet: "DELETE"
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
            if let firstName { json["first_name"] = firstName }
            if let lastName { json["last_name"] = lastName }
            if let email { json["email"] = email }
            if let password { json["password"] = password }
            return try? JSONSerialization.data(withJSONObject: json, options: [])
        case let .createPassage(book, startChapter, endChapter, startVerse, endVerse, translation):
            let json: [String: Any] = [
                "book": book,
                "start_chapter": startChapter,
                "end_chapter": endChapter,
                "start_verse": startVerse,
                "end_verse": endVerse,
                "translation": translation,
            ]
            return try? JSONSerialization.data(withJSONObject: json, options: [])
        case let .patchPassage(_, book, startChapter, endChapter, startVerse, endVerse, translation):
            var json: [String: Any] = [:]
            if let book { json["book"] = book }
            if let startChapter { json["start_chapter"] = startChapter }
            if let endChapter { json["end_chapter"] = endChapter }
            if let startVerse { json["start_verse"] = startVerse }
            if let endVerse { json["end_verse"] = endVerse }
            if let translation { json["translation"] = translation }
            return try? JSONSerialization.data(withJSONObject: json, options: [])
        case let .createStudySet(name, description, positionSeed, colorSeed, theme, passageIds):
            var json: [String: Any] = [
                "user_id": UserStore.shared.currentUser?.id ?? "", // Backend needs user_id in StudySetCreate
                "name": name,
                "mesh_position_seed": positionSeed,
                "mesh_color_seed": colorSeed,
                "mesh_theme": theme,
            ]
            if let description { json["description"] = description }
            if let passageIds { json["passage_ids"] = passageIds }
            return try? JSONSerialization.data(withJSONObject: json, options: [])
        case let .patchStudySet(_, name, description, positionSeed, colorSeed, theme):
            var json: [String: Any] = [:]
            if let name { json["name"] = name }
            if let description { json["description"] = description }
            if let positionSeed { json["mesh_position_seed"] = positionSeed }
            if let colorSeed { json["mesh_color_seed"] = colorSeed }
            if let theme { json["mesh_theme"] = theme }
            return try? JSONSerialization.data(withJSONObject: json, options: [])
        case let .startPracticeSession(passageId):
            let json: [String: Any] = ["passage_id": passageId]
            return try? JSONSerialization.data(withJSONObject: json, options: [])
        case let .completePracticeSession(_, score):
            let json: [String: Any] = ["score": score]
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
