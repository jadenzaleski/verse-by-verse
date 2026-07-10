//
//  Passage.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/7/26.
//

import Foundation
import SwiftData

/// A contiguous range of Bible verses the user memorizes together.
///
/// Carries **no memory state of its own** — the FSRS cards are its
/// ``Verse`` members (shared app-globally), and everything schedule- or
/// score-like on a passage is derived from them: due when its earliest
/// verse is due, Memory Score = average of verse retrievability.
///
/// CloudKit-compatible by design: defaults/optionals everywhere, optional
/// relationships, no unique constraints (uniqueness via upsert).
@Model
final class Passage {
    var book: String = ""
    var startChapter: Int = 1
    var endChapter: Int = 1
    var startVerse: Int = 1
    var endVerse: Int = 1
    var translation: String = "KJV"

    var createdAt: Date = Date()
    /// Record-format version for future lazy migrations (CloudKit is additive-only).
    var schemaVersion: Int = 2

    @Relationship(inverse: \Verse.passages)
    var verses: [Verse]? = []

    @Relationship(inverse: \PracticeSession.passage)
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

// MARK: - Derived memory values (from member verses)

extension Passage {
    /// Member verses in recitation order.
    var orderedVerses: [Verse] {
        (verses ?? []).sorted {
            ($0.chapter, $0.number) < ($1.chapter, $1.number)
        }
    }

    /// Never practiced at all: every verse is still new.
    var isNew: Bool {
        (verses ?? []).allSatisfy(\.isNew)
    }

    /// The passage is due when any of its verses is due (or still new).
    func isDue(at date: Date = .now) -> Bool {
        (verses ?? []).contains { $0.isDue(at: date) }
    }

    /// Earliest scheduled review among the verses; nil while all are new.
    var nextPractice: Date? {
        (verses ?? []).compactMap(\.nextPractice).min()
    }

    /// Most recent practice among the verses.
    var lastPracticed: Date? {
        (verses ?? []).compactMap(\.lastPracticed).max()
    }

    /// Total completed reviews across all verses.
    var totalReps: Int {
        (verses ?? []).reduce(0) { $0 + $1.reps }
    }

    /// Total lapses (Again ratings) across all verses.
    var totalLapses: Int {
        (verses ?? []).reduce(0) { $0 + $1.lapses }
    }

    /// Average completed reviews per verse (rounded down).
    var averageReps: Int {
        let verses = verses ?? []
        guard !verses.isEmpty else { return 0 }
        return verses.reduce(0) { $0 + $1.reps } / verses.count
    }

    /// Average retrievability across all verses (unpracticed verses count
    /// as 0), or nil when nothing has been practiced yet.
    func memoryScore(using scheduler: MemoryScheduler, at date: Date = .now) -> Double? {
        let verses = verses ?? []
        guard !verses.isEmpty, verses.contains(where: { $0.lastPracticed != nil }) else { return nil }
        let total = verses.reduce(0.0) { sum, verse in
            sum + scheduler.retrievability(of: verse.memoryState, at: date)
        }
        return total / Double(verses.count)
    }
}

// MARK: - Uniqueness & creation

extension Passage {
    /// Returns an existing passage with the same reference + translation as
    /// the (not yet inserted) candidate, if any.
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

    /// Attaches the shared `Verse` cards for this passage's range, creating
    /// any that don't exist yet. Requires Bible metadata for per-chapter
    /// verse counts on cross-chapter ranges.
    func attachVerses(using bibleStore: BibleStore, in context: ModelContext) throws {
        var members: [Verse] = []
        for chapter in startChapter ... endChapter {
            let first = chapter == startChapter ? startVerse : 1
            let last = chapter == endChapter ? endVerse : bibleStore.verseCount(for: book, chapter: chapter)
            guard last >= first else { continue }
            for number in first ... last {
                try members.append(Verse.findOrCreate(
                    translation: translation, book: book, chapter: chapter, number: number, in: context,
                ))
            }
        }
        verses = members
    }
}
