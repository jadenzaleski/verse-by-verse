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

    /// What you actually got last time (0…1) — the newest review's score.
    /// A recorded fact, unlike the FSRS Memory Score, which is an estimate.
    var lastResult: Double? {
        (reviews ?? []).max { $0.reviewedAt < $1.reviewedAt }?.score
    }

    func isDue(at date: Date = .now) -> Bool {
        if let next = nextPractice {
            return next <= date
        }
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
    /// Positions (0-based, in ``VerseWords/canonical(_:)`` order) of the words
    /// missed in a scored step. Positions only; the words themselves are never
    /// stored. Read them through ``missedWordIndices(forText:)``.
    var missedWordIndices: [Int] = []
    /// ``VerseWords/fingerprint(of:)`` of the verse text when this review was
    /// recorded; empty when unknown. It says which text the positions belong to.
    var textFingerprint: String = ""
    /// Record-format version for future lazy migrations.
    var schemaVersion: Int = 1

    var verse: Verse?
    var session: PracticeSession?

    init(reviewedAt: Date = Date()) {
        self.reviewedAt = reviewedAt
    }
}

extension VerseReview {
    /// The missed-word positions, but only if they were recorded against this
    /// exact set of words. `nil` (not empty) means "can't tell", so a changed
    /// verse is never shown wrong words.
    func missedWordIndices(forText text: String) -> [Int]? {
        guard !textFingerprint.isEmpty, textFingerprint == VerseWords.fingerprint(of: text) else {
            return nil
        }
        return missedWordIndices
    }
}

/// How often each word of a verse was missed, from the reviews recorded
/// against its current text.
struct MissSummary: Equatable {
    /// Word position (see ``VerseWords``) → number of reviews that missed it.
    /// Positions never missed are absent.
    var counts: [Int: Int] = [:]
    /// Reviews that were recorded against this exact text. Zero means there is
    /// no history to draw on (never practiced, or the text has changed).
    var reviewCount = 0
}

extension Verse {
    /// Misses per word position, counting only reviews recorded against
    /// `text`'s current words.
    func missSummary(forText text: String) -> MissSummary {
        let fingerprint = VerseWords.fingerprint(of: text)
        var summary = MissSummary()
        for review in reviews ?? [] where review.textFingerprint == fingerprint {
            summary.reviewCount += 1
            for index in review.missedWordIndices {
                summary.counts[index, default: 0] += 1
            }
        }
        return summary
    }
}
