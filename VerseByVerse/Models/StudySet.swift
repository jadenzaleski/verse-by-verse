//
//  StudySet.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

enum MeshTheme: String, CaseIterable, Identifiable {
    case ocean
    case sunset
    case forest

    var id: String {
        rawValue
    }

    var displayName: String {
        rawValue.capitalized
    }
}

struct StudySet: Identifiable, Equatable {
    let id: Int
    let userId: String
    let name: String
    let description: String?
    let meshPositionSeed: Int
    let meshColorSeed: Int
    let meshTheme: MeshTheme
    let createdAt: Date
    let modifiedAt: Date
}

extension MeshThemeResponse {
    func toDomain() -> MeshTheme {
        switch self {
        case .ocean: .ocean
        case .sunset: .sunset
        case .forest: .forest
        }
    }
}

extension StudySetReadResponse {
    func toDomain() -> StudySet {
        StudySet(
            id: id,
            userId: userId,
            name: name,
            description: description,
            meshPositionSeed: meshPositionSeed,
            meshColorSeed: meshColorSeed,
            meshTheme: meshTheme.toDomain(),
            createdAt: createdAt,
            modifiedAt: modifiedAt,
        )
    }
}
