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
            for score in [0.92, 0.95, 0.75].prefix(3 - (index % 2)) {
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
                    review.verse = verse
                    review.session = session
                    verse.memoryState = outcome.state
                }
                reviewDate = min(passage.nextPractice ?? reviewDate, Date())
            }
        }

        // A standalone verse the user memorizes on its own.
        if let standalone = try? Verse.findOrCreate(
            translation: "KJV", book: "Philippians", chapter: 4, number: 13, in: context,
        ) {
            standalone.addedDirectly = true
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
            context.insert(set)
        }

        try? context.save()
    }
}
