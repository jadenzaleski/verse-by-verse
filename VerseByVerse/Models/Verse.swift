//
//  Verse.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/10/26.
//

import Foundation
import SwiftData

/// A single Bible verse — the FSRS memory card. Verses are app-global:
/// one card per (translation, book, chapter, number), shared by every
/// passage and set that contains it, so overlapping content shares memory
/// state. `addedDirectly` marks verses the user memorizes standalone
/// (outside any passage).
///
/// No verse *text* is stored here — licensing limits local scripture
/// storage to two weeks, so text lives only in the expiring HTTP cache.
///
/// CloudKit-compatible by design: defaults/optionals everywhere, optional
/// relationships, no unique constraints (uniqueness via ``findOrCreate``).
@Model
final class Verse {
    var translation: String = "KJV"
    var book: String = ""
    var chapter: Int = 1
    var number: Int = 1
    /// True when the user added this verse on its own (not via a passage).
    var addedDirectly: Bool = false

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

    var passages: [Passage]? = []
    var studySets: [StudySet]? = []

    @Relationship(deleteRule: .cascade, inverse: \VerseReview.verse)
    var reviews: [VerseReview]? = []

    init(
        translation: String = "KJV",
        book: String = "",
        chapter: Int = 1,
        number: Int = 1,
        addedDirectly: Bool = false,
    ) {
        self.translation = translation
        self.book = book
        self.chapter = chapter
        self.number = number
        self.addedDirectly = addedDirectly
    }
}

// MARK: - Reference helpers

extension Verse {
    var reference: String {
        "\(book) \(chapter):\(number)"
    }

    var selectionKey: BibleSelectionKey {
        BibleSelectionKey(
            translation: translation,
            book: book,
            startChapter: chapter,
            startVerse: number,
            endChapter: chapter,
            endVerse: number,
        )
    }

    var isNew: Bool {
        reps == 0
    }

    func isDue(at date: Date = .now) -> Bool {
        if let next = nextPractice { return next <= date }
        return isNew
    }
}

// MARK: - Memory state bridge

extension Verse {
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

// MARK: - Uniqueness & lifecycle

extension Verse {
    /// Returns the existing global card for this reference, if any.
    /// SwiftData with CloudKit can't enforce unique constraints, so all
    /// creation paths go through ``findOrCreate``.
    static func existing(
        translation: String,
        book: String,
        chapter: Int,
        number: Int,
        in context: ModelContext,
    ) throws -> Verse? {
        var descriptor = FetchDescriptor<Verse>(
            predicate: #Predicate { verse in
                verse.translation == translation
                    && verse.book == book
                    && verse.chapter == chapter
                    && verse.number == number
            },
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Fetches the shared card for this reference, inserting a fresh one if
    /// none exists yet. Memory state is preserved across containers.
    static func findOrCreate(
        translation: String,
        book: String,
        chapter: Int,
        number: Int,
        in context: ModelContext,
    ) throws -> Verse {
        if let found = try existing(
            translation: translation, book: book, chapter: chapter, number: number, in: context,
        ) {
            return found
        }
        let verse = Verse(translation: translation, book: book, chapter: chapter, number: number)
        context.insert(verse)
        return verse
    }

    /// Deletes verses that nothing references: not in any passage or set and
    /// not added directly by the user. Their reviews cascade away with them.
    /// Call after deleting a passage/set or removing memberships (works
    /// mid-transaction: containers pending deletion don't count as references).
    static func sweepOrphans(in context: ModelContext) throws {
        let all = try context.fetch(FetchDescriptor<Verse>())
        for verse in all where !verse.addedDirectly
            && (verse.passages ?? []).allSatisfy(\.isDeleted)
            && (verse.studySets ?? []).allSatisfy(\.isDeleted)
        {
            context.delete(verse)
        }
    }
}

/// One verse's outcome within a completed practice session — the append-only
/// FSRS review log. `stabilityAfter`/`difficultyAfter` snapshots let charts
/// draw the exact retrievability curve without replaying history.
@Model
final class VerseReview {
    var reviewedAt: Date = Date()
    var correctCount: Int = 0
    var totalCount: Int = 0
    /// Per-verse score 0…1 for this review.
    var score: Double = 0
    /// FSRS rating applied: 1 = Again … 4 = Easy.
    var rating: Int = 0
    var stabilityAfter: Double = 0
    var difficultyAfter: Double = 0
    /// Card state after the review (0…3).
    var stateAfter: Int = 0
    /// Record-format version for future lazy migrations.
    var schemaVersion: Int = 1

    var verse: Verse?
    var session: PracticeSession?

    init(reviewedAt: Date = Date()) {
        self.reviewedAt = reviewedAt
    }
}
