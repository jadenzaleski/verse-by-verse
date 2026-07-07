//
//  AppModelContainer.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/7/26.
//

import Foundation
import SwiftData

/// Builds the app's SwiftData container.
///
/// CloudKit sync is deliberately off (`cloudKitDatabase: .none`) — the models
/// are CloudKit-compatible so the future flip is a one-line change here plus
/// entitlements (docs/cloudkit-implementation-guide.md §1.1).
enum AppModelContainer {
    static let schema = Schema([
        Passage.self,
        StudySet.self,
        PracticeSession.self,
        PracticeActivity.self,
    ])

    static func make(inMemory: Bool = false) -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none,
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Unrecoverable at app root: no store means no app. In practice this
            // only fires for an incompatible on-disk schema during development.
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
