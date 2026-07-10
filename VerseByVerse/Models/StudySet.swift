//
//  StudySet.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation
import SwiftData

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

/// A user-defined collection of passages with a generated mesh-gradient cover.
///
/// CloudKit-compatible by design: defaults everywhere, optional relationships,
/// no unique constraints. `description` is `setDescription` because `@Model`
/// classes can't shadow `NSObject.description`.
@Model
final class StudySet {
    var name: String = ""
    var setDescription: String?
    var meshPositionSeed: Int = 0
    var meshColorSeed: Int = 0
    private var meshThemeRaw: String = MeshTheme.ocean.rawValue
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    /// Record-format version for future lazy migrations (CloudKit is additive-only).
    var schemaVersion: Int = 1

    @Relationship(inverse: \Passage.studySets)
    var passages: [Passage]? = []

    @Relationship(inverse: \Verse.studySets)
    var verses: [Verse]? = []

    init(
        name: String = "",
        setDescription: String? = nil,
        meshPositionSeed: Int = Int.random(in: 1 ... 99999),
        meshColorSeed: Int = Int.random(in: 1 ... 99999),
        meshTheme: MeshTheme = .ocean,
    ) {
        self.name = name
        self.setDescription = setDescription
        self.meshPositionSeed = meshPositionSeed
        self.meshColorSeed = meshColorSeed
        meshThemeRaw = meshTheme.rawValue
    }

    var meshTheme: MeshTheme {
        get { MeshTheme(rawValue: meshThemeRaw) ?? .ocean }
        set { meshThemeRaw = newValue.rawValue }
    }
}
