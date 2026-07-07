//
//  StudySetModels.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

enum MeshThemeResponse: String, Codable {
    case ocean
    case sunset
    case forest
}

struct StudySetReadResponse: Codable {
    let id: Int
    let userId: String
    let name: String
    let description: String?
    let meshPositionSeed: Int
    let meshColorSeed: Int
    let meshTheme: MeshThemeResponse
    let createdAt: Date
    let modifiedAt: Date
    let passageIds: [Int]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, description
        case meshPositionSeed = "mesh_position_seed"
        case meshColorSeed = "mesh_color_seed"
        case meshTheme = "mesh_theme"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
        case passageIds = "passage_ids"
    }
}

/// Returned by GET /study-set/{id} and passage add/remove endpoints (includes passages array).
struct StudySetDetailResponse: Codable {
    let id: Int
    let userId: String
    let name: String
    let description: String?
    let meshPositionSeed: Int
    let meshColorSeed: Int
    let meshTheme: MeshThemeResponse
    let createdAt: Date
    let modifiedAt: Date
    let passages: [UserPassageReadResponse]

    enum CodingKeys: String, CodingKey {
        case id, name, description, passages
        case userId = "user_id"
        case meshPositionSeed = "mesh_position_seed"
        case meshColorSeed = "mesh_color_seed"
        case meshTheme = "mesh_theme"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
    }

    var passageIds: [Int] {
        passages.map(\.id)
    }
}

struct StudySetCreateRequest: Codable {
    let userId: String
    let name: String
    let description: String?
    let meshPositionSeed: Int
    let meshColorSeed: Int
    let meshTheme: MeshThemeResponse
    let passageIds: [Int]?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name, description
        case meshPositionSeed = "mesh_position_seed"
        case meshColorSeed = "mesh_color_seed"
        case meshTheme = "mesh_theme"
        case passageIds = "passage_ids"
    }
}
