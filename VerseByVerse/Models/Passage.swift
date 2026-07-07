//
//  Passage.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/7/26.
//

import Foundation
import SwiftData

/// A Bible passage the user is memorizing, with its FSRS memory state.
///
/// CloudKit-compatible by design (see docs/cloudkit-implementation-guide.md §2):
/// every property has a default or is optional, relationships are optional,
/// and uniqueness is enforced by ``upsert(in:)`` rather than constraints.
@Model
final class Passage {
    var book: String = ""
    var startChapter: Int = 1
    var endChapter: Int = 1
    var startVerse: Int = 1
    var endVerse: Int = 1
    var translation: String = "KJV"

    // MARK: FSRS memory state (device-managed via MemoryScheduler)

    var lastPracticed: Date?
    var nextPractice: Date?
    var stability: Double?
    var difficulty: Double?
    /// 0 = new, 1 = learning, 2 = review, 3 = relearning.
    var state: Int = 0
    /// Learning/relearning step index; meaningful only in states 1 and 3.
    var step: Int = 0
    var reps: Int = 0
    var lapses: Int = 0

    var createdAt: Date = Date()
    /// Record-format version for future lazy migrations (CloudKit is additive-only).
    var schemaVersion: Int = 1

    @Relationship(deleteRule: .cascade, inverse: \PracticeSession.passage)
    var sessions: [PracticeSession]? = []

    var studySets: [StudySet]? = []

    init(
        book: String = "",
        startChapter: Int = 1,
        endChapter: Int = 1,
        startVerse: Int = 1,
        endVerse: Int = 1,
        translation: String = "KJV",
    ) {
        self.book = book
        self.startChapter = startChapter
        self.endChapter = endChapter
        self.startVerse = startVerse
        self.endVerse = endVerse
        self.translation = translation
    }
}

// MARK: - Reference helpers

extension Passage {
    var reference: String {
        if startChapter == endChapter {
            if startVerse == endVerse {
                "\(book) \(startChapter):\(startVerse)"
            } else {
                "\(book) \(startChapter):\(startVerse)-\(endVerse)"
            }
        } else {
            "\(book) \(startChapter):\(startVerse)-\(endChapter):\(endVerse)"
        }
    }

    var selectionKey: BibleSelectionKey {
        BibleSelectionKey(
            translation: translation,
            book: book,
            startChapter: startChapter,
            startVerse: startVerse,
            endChapter: endChapter,
            endVerse: endVerse,
        )
    }

    func verseCount(using bibleStore: BibleStore) -> Int {
        if startChapter == endChapter {
            return endVerse - startVerse + 1
        }
        var total = bibleStore.verseCount(for: book, chapter: startChapter) - startVerse + 1
        for chapter in (startChapter + 1) ..< endChapter {
            total += bibleStore.verseCount(for: book, chapter: chapter)
        }
        total += endVerse
        return total
    }
}

// MARK: - Memory state bridge

extension Passage {
    /// Snapshot of the FSRS fields for the ``MemoryScheduler`` seam.
    var memoryState: MemoryState {
        get {
            MemoryState(
                stability: stability,
                difficulty: difficulty,
                state: state,
                step: step,
                due: nextPractice,
                lastReviewed: lastPracticed,
                reps: reps,
                lapses: lapses,
            )
        }
        set {
            stability = newValue.stability
            difficulty = newValue.difficulty
            state = newValue.state
            step = newValue.step
            nextPractice = newValue.due
            lastPracticed = newValue.lastReviewed
            reps = newValue.reps
            lapses = newValue.lapses
        }
    }
}

// MARK: - Uniqueness

extension Passage {
    /// Returns an existing passage with the same reference + translation as
    /// the (not yet inserted) candidate, if any. SwiftData with CloudKit can't
    /// enforce unique constraints, so the Add Passage flow upserts instead of
    /// blindly inserting.
    static func existingDuplicate(of candidate: Passage, in context: ModelContext) throws -> Passage? {
        let book = candidate.book
        let startChapter = candidate.startChapter
        let endChapter = candidate.endChapter
        let startVerse = candidate.startVerse
        let endVerse = candidate.endVerse
        let translation = candidate.translation

        var descriptor = FetchDescriptor<Passage>(
            predicate: #Predicate { passage in
                passage.book == book
                    && passage.startChapter == startChapter
                    && passage.endChapter == endChapter
                    && passage.startVerse == startVerse
                    && passage.endVerse == endVerse
                    && passage.translation == translation
            },
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
