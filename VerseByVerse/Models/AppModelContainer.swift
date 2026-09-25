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
        Verse.self,
        VerseReview.self,
        Passage.self,
        StudySet.self,
        PracticeSession.self,
        PracticeActivity.self,
    ])

    private static let log = AppLog.category("AppModelContainer")

    /// Set when `make()` had to quarantine a corrupt store and start fresh, so
    /// the app can tell the user their local data was reset.
    private(set) static var didRecoverFromCorruptStore = false

    static func make(inMemory: Bool = false) -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none,
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            log.fault("Store failed to open at \(configuration.url.path): \(error). Quarantining and starting fresh.")
        }

        // The store is corrupt (or its on-disk schema can't be opened). Move it
        // out of the way — never delete — so a fresh store can be created at the
        // same URL and the app can still launch; the quarantined files remain in
        // Application Support if the data is ever worth trying to recover.
        quarantineStore(at: configuration.url)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            didRecoverFromCorruptStore = true
            return container
        } catch {
            log.fault("Fresh store also failed to open: \(error). Falling back to an in-memory store for this launch.")
        }

        // Reaching here means even a brand-new store can't be opened, which
        // points at a schema/model bug rather than on-disk corruption — that is
        // a genuine programmer error, so crashing is appropriate.
        let fallbackConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none,
        )
        do {
            return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
        } catch {
            fatalError("Failed to create even an in-memory ModelContainer: \(error)")
        }
    }

    private static func quarantineStore(at url: URL) {
        let fileManager = FileManager.default
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let suffix = formatter.string(from: .now)
        for sidecar in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: url.path + sidecar)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            let destination = URL(fileURLWithPath: "\(url.path).corrupt-\(suffix)\(sidecar)")
            do {
                try fileManager.moveItem(at: source, to: destination)
            } catch {
                log.fault("Failed to quarantine \(source.lastPathComponent): \(error)")
            }
        }
    }
}
