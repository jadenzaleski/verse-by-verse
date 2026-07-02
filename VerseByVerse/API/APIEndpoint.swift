//
//  APIEndpoint.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import CryptoKit
import Foundation

enum APIEndpoint: Hashable {
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
    case createStudySet(name: String,
                        description: String?,
                        positionSeed: Int,
                        colorSeed: Int,
                        theme: String,
                        passageIds: [Int]?)
    case patchStudySet(id: Int,
                       name: String?,
                       description: String?,
                       positionSeed: Int?,
                       colorSeed: Int?,
                       theme: String?)
    case deleteStudySet(id: Int)
    case addPassageToStudySet(studySetId: Int, passageId: Int)
    case removePassageFromStudySet(studySetId: Int, passageId: Int)
    // Practice Sessions
    case getMyPracticeSessions
    case startPracticeSession(passageId: Int)
    case completePracticeSession(id: Int, activities: [ActivityResult])
    case deletePracticeSession(id: Int)
    /// Other
    case getHealth

    var debugIdentifier: String {
        var parts: [String] = [method, path]

        if let items = queryItems, !items.isEmpty {
            let query = items
                .sorted { $0.name < $1.name }
                .map { "\($0.name)=\($0.value ?? "")" }
                .joined(separator: "&")
            parts.append(query)
        }

        if let body {
            parts.append("body:\(body.sha256Hex)")
        }

        return parts.joined(separator: " | ")
    }

    var cacheIdentifier: String {
        // Build canonical bytes from method, path, sorted query, then append body bytes with a delimiter, and hash.
        var parts: [String] = [method, path]

        if let items = queryItems, !items.isEmpty {
            let query = items
                .sorted { $0.name < $1.name }
                .map { "\($0.name)=\($0.value ?? "")" }
                .joined(separator: "&")
            parts.append(query)
        }

        let canonical = parts.joined(separator: " ")
        var data = Data(canonical.utf8)

        if let body {
            data.append(Data([0x1F])) // Unit Separator delimiter
            data.append(body)
        }

        return data.sha256Hex
    }

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
        case let .deletePracticeSession(id): "/practice-session/\(id)"
        }
    }

    var method: String {
        switch self {
        case .postLogin,
             .postRegister,
             .postRefresh,
             .createPassage,
             .createStudySet,
             .addPassageToStudySet,
             .startPracticeSession,
             .completePracticeSession: "POST"
        case .patchUser, .patchPassage, .patchStudySet: "PATCH"
        case .deletePassage, .deleteStudySet, .removePassageFromStudySet, .deletePracticeSession: "DELETE"
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
        case let .completePracticeSession(_, activities):
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try? encoder.encode(CompletePracticeSessionBody(activities: activities))
        default:
            return nil
        }
    }

    var invalidates: [APIEndpoint] {
        switch self {
        case .patchUser:
            [.getUser]
        case .createPassage:
            [.getMyPassages]
        case let .patchPassage(id, _, _, _, _, _, _):
            [.getPassage(id: id), .getMyPassages]
        case let .deletePassage(id):
            [.getPassage(id: id), .getMyPassages]
        case .createStudySet:
            [.getMyStudySets]
        case let .patchStudySet(id, _, _, _, _, _):
            [.getStudySet(id: id), .getMyStudySets]
        case let .deleteStudySet(id):
            [.getStudySet(id: id), .getMyStudySets]
        case let .addPassageToStudySet(sid, _), let .removePassageFromStudySet(sid, _):
            [.getStudySet(id: sid), .getMyStudySets]
        case .completePracticeSession:
            [.getMyPracticeSessions, .getMyPassages]
        case .deletePracticeSession:
            [.getMyPracticeSessions]
        default:
            []
        }
    }

    /// The APIEndpoint Time To Live, or time in seconds before it expires and is purged.
    var ttl: TimeInterval? {
        switch self {
        case .getUser,
             .getBibleSelection,
             .getPassage,
             .getMyPassages,
             .getMyStudySets,
             .getStudySet,
             .getMyPracticeSessions:
            60
        case .getBibleBooks,
             .getBibleTranslations:
            30 * 24 * 60 * 60 // 30 days
        default:
            nil
        }
    }

    var request: URLRequest {
        let log = AppLog.category("APIEndpoint.request")
        let base = AppFunctions.apiBaseURL.appendingPathComponent(path)

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

private struct CompletePracticeSessionBody: Encodable {
    let activities: [ActivityResult]
}

private extension Data {
    var sha256Hex: String {
        SHA256.hash(data: self).map { String(format: "%02x", $0) }.joined()
    }
}

private extension String {
    var sha256Hex: String {
        Data(utf8).sha256Hex
    }
}
