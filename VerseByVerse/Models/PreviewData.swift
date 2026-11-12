//
//  PreviewData.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/7/26.
//

import Foundation
import SwiftData

/// In-memory SwiftData container seeded with sample data for previews.
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let container = AppModelContainer.make(inMemory: true)
        seed(container.mainContext)
        return container
    }()

    static var passages: [Passage] {
        (try? container.mainContext.fetch(
            FetchDescriptor<Passage>(sortBy: [SortDescriptor(\.createdAt)]),
        )) ?? []
    }

    static var studySets: [StudySet] {
        (try? container.mainContext.fetch(
            FetchDescriptor<StudySet>(sortBy: [SortDescriptor(\.createdAt)]),
        )) ?? []
    }

    static var verses: [Verse] {
        (try? container.mainContext.fetch(
            FetchDescriptor<Verse>(sortBy: [SortDescriptor(\.createdAt)]),
        )) ?? []
    }

    static var samplePassage: Passage {
        passages.first ?? Passage(book: "John", startChapter: 3, endChapter: 3, startVerse: 16, endVerse: 17)
    }

    static var sampleVerse: Verse {
        verses.first ?? Verse(book: "John", chapter: 3, number: 16)
    }

    /// A store holding the sample text for the seeded passage and verse, so
    /// detail previews render offline (and the heatmap has words to color).
    static var bibleStore: BibleStore {
        let passage = samplePassage
        let verse = sampleVerse
        let selections = [
            selection(key: passage.selectionKey, verses: passage.orderedVerses),
            selection(key: verse.selectionKey, verses: [verse]),
        ]
        return BibleStore.offline(selections: selections.compactMap(\.self))
    }

    /// The sample text for `verses`, or `nil` if any of them has none.
    private static func selection(key: BibleSelectionKey, verses: [Verse]) -> BibleSelection? {
        let selectionVerses = verses.compactMap { verse -> SelectionVerse? in
            sampleText[verse.reference].map { text in
                SelectionVerse(
                    id: verse.reference, book: verse.book, chapter: verse.chapter, verse: verse.number, text: text,
                )
            }
        }
        guard selectionVerses.count == verses.count else { return nil }
        return BibleSelection(
            translation: key.translation, book: key.book,
            startChapter: key.startChapter, startVerse: key.startVerse,
            endChapter: key.endChapter, endVerse: key.endVerse,
            verses: selectionVerses, fumsTokens: [],
        )
    }

    /// Records which words a sample verse's `sessionIndex`-th session missed.
    private static func applySampleMisses(to review: VerseReview, verse: Verse, sessionIndex: Int) {
        guard let text = sampleText[verse.reference], let misses = sampleMisses[verse.reference] else { return }
        review.missedWordIndices = misses[min(sessionIndex, misses.count - 1)]
        review.textFingerprint = VerseWords.fingerprint(of: text)
    }

    /// KJV (public domain) text for the sample verses, keyed by reference.
    /// Only previews use it; the app never stores verse text.
    private static let sampleText: [String: String] = [
        "John 3:16": "For God so loved the world, that he gave his only begotten Son, "
            + "that whosoever believeth in him should not perish, but have everlasting life.",
        "John 3:17": "For God sent not his Son into the world to condemn the world; "
            + "but that the world through him might be saved.",
    ]

    /// Word positions missed in each of a sample verse's practice sessions
    /// (oldest first), so the heatmap shows a spread from green to red.
    private static let sampleMisses: [String: [[Int]]] = [
        // begotten (11) and believeth (15) three times; whosoever (14), everlasting (23) twice; should (18) once.
        "John 3:16": [[11, 14, 15, 23], [11, 15], [11, 14, 15, 18, 23]],
        // condemn (10) three times; through (17) twice; might (19) once.
        "John 3:17": [[10, 17], [10], [10, 17, 19]],
    ]

    private struct SeedRef {
        let book: String
        let chapter: Int
        let startVerse: Int
        let endVerse: Int
    }

    private struct SeedSet {
        let name: String
        let details: String?
        let theme: MeshTheme
    }

    private static func seed(_ context: ModelContext) {
        let scheduler = FSRSScheduler()
        let refs: [SeedRef] = [
            SeedRef(book: "John", chapter: 3, startVerse: 16, endVerse: 17),
            SeedRef(book: "Romans", chapter: 8, startVerse: 28, endVerse: 30),
            SeedRef(book: "Psalms", chapter: 23, startVerse: 1, endVerse: 6),
            SeedRef(book: "Genesis", chapter: 1, startVerse: 1, endVerse: 3),
            SeedRef(book: "Matthew", chapter: 5, startVerse: 3, endVerse: 12),
            SeedRef(book: "Philippians", chapter: 4, startVerse: 6, endVerse: 7),
        ]

        var passages: [Passage] = []
        for (index, ref) in refs.enumerated() {
            let passage = Passage(
                book: ref.book,
                startChapter: ref.chapter,
                endChapter: ref.chapter,
                startVerse: ref.startVerse,
                endVerse: ref.endVerse,
                translation: ["KJV", "NIV", "ESV"][index % 3],
            )
            context.insert(passage)

            // Attach shared verse cards (single-chapter seeds; no Bible data needed).
            var members: [Verse] = []
            for number in ref.startVerse ... ref.endVerse {
                if let verse = try? Verse.findOrCreate(
                    translation: passage.translation,
                    book: ref.book,
                    chapter: ref.chapter,
                    number: number,
                    in: context,
                ) {
                    members.append(verse)
                }
            }
            passage.verses = members
            passages.append(passage)

            // Give the first few passages a practice history.
            guard index < 4 else { continue }
            var reviewDate = Date().addingTimeInterval(Double(-(10 - index)) * 86400)
            for (sessionIndex, score) in [0.92, 0.95, 0.75].prefix(3 - (index % 2)).enumerated() {
                let session = PracticeSession(startDate: reviewDate)
                session.endDate = reviewDate.addingTimeInterval(180)
                session.score = score
                session.rating = MemoryScoring.rating(forScore: score)
                session.passage = passage
                context.insert(session)

                for verse in members {
                    let outcome = scheduler.processReview(
                        state: verse.memoryState, score: score, at: reviewDate,
                    )
                    let review = VerseReview(reviewedAt: reviewDate)
                    review.score = score
                    review.rating = outcome.rating
                    review.correctCount = Int(score * 10)
                    review.totalCount = 10
                    review.stabilityAfter = outcome.state.stability ?? 0
                    review.difficultyAfter = outcome.state.difficulty ?? 0
                    review.stateAfter = outcome.state.state
                    applySampleMisses(to: review, verse: verse, sessionIndex: sessionIndex)
                    review.verse = verse
                    review.session = session
                    verse.memoryState = outcome.state
                }
                reviewDate = min(passage.nextPractice ?? reviewDate, Date())
            }
        }

        // Standalone verses the user memorizes on their own.
        var standaloneVerses: [Verse] = []
        for (book, chapter, number) in [("Philippians", 4, 13), ("John", 14, 6)] {
            if let standalone = try? Verse.findOrCreate(
                translation: "KJV", book: book, chapter: chapter, number: number, in: context,
            ) {
                standalone.addedDirectly = true
                standaloneVerses.append(standalone)
            }
        }

        let seedSets: [SeedSet] = [
            SeedSet(name: "Sermon on the Mount",
                    details: "Matthew 5-7, the core teachings of Jesus.", theme: .ocean),
            SeedSet(name: "Psalms of Praise", details: nil, theme: .sunset),
            SeedSet(name: "Romans Road", details: "Key verses outlining the gospel.", theme: .forest),
        ]
        for (index, entry) in seedSets.enumerated() {
            let set = StudySet(
                name: entry.name,
                setDescription: entry.details,
                meshPositionSeed: 1024 * (index + 1),
                meshColorSeed: 4096 * (index + 1),
                meshTheme: entry.theme,
            )
            set.passages = Array(passages.prefix(index + 2))
            // The first set mixes passages with loose verses (e.g. for SetDetailView previews).
            if index == 0 {
                set.verses = standaloneVerses
            }
            context.insert(set)
        }

        try? context.save()
    }
}
