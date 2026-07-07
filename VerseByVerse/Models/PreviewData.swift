//
//  PreviewData.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/7/26.
//

#if DEBUG
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

        static var samplePassage: Passage {
            passages.first ?? Passage(book: "John", startChapter: 3, endChapter: 3, startVerse: 16, endVerse: 16)
        }

        private struct SeedRef {
            let book: String
            let chapter: Int
            let startVerse: Int
            let endVerse: Int
        }

        private static func seed(_ context: ModelContext) {
            let scheduler = FSRSScheduler()
            let books: [SeedRef] = [
                SeedRef(book: "John", chapter: 3, startVerse: 16, endVerse: 16),
                SeedRef(book: "Romans", chapter: 8, startVerse: 28, endVerse: 30),
                SeedRef(book: "Psalms", chapter: 23, startVerse: 1, endVerse: 6),
                SeedRef(book: "Genesis", chapter: 1, startVerse: 1, endVerse: 3),
                SeedRef(book: "Matthew", chapter: 5, startVerse: 3, endVerse: 12),
                SeedRef(book: "Philippians", chapter: 4, startVerse: 6, endVerse: 7),
            ]

            var passages: [Passage] = []
            for (index, entry) in books.enumerated() {
                let passage = Passage(
                    book: entry.book,
                    startChapter: entry.chapter,
                    endChapter: entry.chapter,
                    startVerse: entry.startVerse,
                    endVerse: entry.endVerse,
                    translation: ["KJV", "NIV", "ESV"][index % 3],
                )
                context.insert(passage)
                passages.append(passage)

                // Give the first few passages a practice history.
                guard index < 4 else { continue }
                var reviewDate = Date().addingTimeInterval(Double(-(10 - index)) * 86400)
                for score in [0.85, 0.9, 0.7].prefix(3 - (index % 2)) {
                    let outcome = scheduler.processReview(state: passage.memoryState, score: score, at: reviewDate)
                    let session = PracticeSession(startDate: reviewDate)
                    session.endDate = reviewDate.addingTimeInterval(180)
                    session.score = score
                    session.rating = outcome.rating
                    session.scheduledDays = Int(outcome.intervalDays)
                    session.state = passage.state
                    session.passage = passage
                    context.insert(session)
                    passage.memoryState = outcome.state
                    reviewDate = min(passage.nextPractice ?? reviewDate, Date())
                }
            }

            let setNames: [(String, String?, MeshTheme)] = [
                ("Sermon on the Mount", "Matthew 5-7, the core teachings of Jesus.", .ocean),
                ("Psalms of Praise", nil, .sunset),
                ("Romans Road", "Key verses outlining the gospel.", .forest),
            ]
            for (index, entry) in setNames.enumerated() {
                let set = StudySet(
                    name: entry.0,
                    setDescription: entry.1,
                    meshPositionSeed: 1024 * (index + 1),
                    meshColorSeed: 4096 * (index + 1),
                    meshTheme: entry.2,
                )
                set.passages = Array(passages.prefix(index + 2))
                context.insert(set)
            }

            try? context.save()
        }
    }
#endif
