//
//  PersistenceTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 7/7/26.
//

import Foundation
import SwiftData
import Testing
@testable import VerseByVerse

/// SwiftData layer tests against an in-memory container: passage uniqueness
/// (upsert instead of constraints), the practice-completion write path, and
/// relationship/cascade rules.
@MainActor
struct PersistenceTests {
    /// Retained for the lifetime of each test — a ModelContext must not outlive
    /// its container (SwiftData traps on insert/save if it does).
    private let container = AppModelContainer.make(inMemory: true)

    private func makeContext() -> ModelContext {
        container.mainContext
    }

    private func insertJohn316(_ context: ModelContext) throws -> Passage {
        let passage = Passage(book: "John", startChapter: 3, endChapter: 3, startVerse: 16, endVerse: 16)
        context.insert(passage)
        try context.save()
        return passage
    }

    @Test func `existing finds duplicate reference`() throws {
        let context = makeContext()
        _ = try insertJohn316(context)

        let duplicate = try Passage.existing(
            matching: "John", startChapter: 3, endChapter: 3,
            startVerse: 16, endVerse: 16, translation: "KJV",
            in: context,
        )
        #expect(duplicate != nil)

        let differentTranslation = try Passage.existing(
            matching: "John", startChapter: 3, endChapter: 3,
            startVerse: 16, endVerse: 16, translation: "NIV",
            in: context,
        )
        #expect(differentTranslation == nil)

        let differentRange = try Passage.existing(
            matching: "John", startChapter: 3, endChapter: 3,
            startVerse: 16, endVerse: 17, translation: "KJV",
            in: context,
        )
        #expect(differentRange == nil)
    }

    @Test func `practice completion persists session and updates memory state`() throws {
        let context = makeContext()
        let passage = try insertJohn316(context)
        let scheduler = FSRSScheduler()
        let reviewDate = Date(timeIntervalSince1970: 1_767_268_800)

        // Mirror SessionView.completeSession's write path.
        let outcome = scheduler.processReview(state: passage.memoryState, score: 0.85, at: reviewDate)
        let session = PracticeSession(startDate: reviewDate.addingTimeInterval(-180))
        session.endDate = reviewDate
        session.score = 0.85
        session.rating = outcome.rating
        session.scheduledDays = Int(outcome.intervalDays)
        session.state = passage.state
        session.passage = passage
        let activity = PracticeActivity(position: 0, type: "Verbal Recite", correctCount: 1, totalCount: 1)
        activity.session = session
        context.insert(session)
        passage.memoryState = outcome.state
        try context.save()

        // Memory state landed on the passage.
        #expect(passage.reps == 1)
        #expect(passage.stability != nil)
        #expect(passage.lastPracticed == reviewDate)
        #expect(passage.nextPractice != nil)

        // Session + activity landed and are linked.
        #expect(passage.sessions?.count == 1)
        let saved = try #require(passage.sessions?.first)
        #expect(saved.rating == 3)
        #expect(saved.isCompleted)
        #expect(saved.activities?.count == 1)
    }

    @Test func `memory state round trips through passage`() {
        let passage = Passage(book: "Psalms", startChapter: 23, endChapter: 23, startVerse: 1, endVerse: 6)
        #expect(passage.memoryState == .new)

        let scheduler = FSRSScheduler()
        let outcome = scheduler.processReview(state: passage.memoryState, score: 0.95, at: .now)
        passage.memoryState = outcome.state
        #expect(passage.memoryState == outcome.state)
        #expect(passage.state == outcome.state.state)
        #expect(passage.nextPractice == outcome.state.due)
    }

    @Test func `deleting passage cascades sessions but not sets`() throws {
        let context = makeContext()
        let passage = try insertJohn316(context)

        let session = PracticeSession(startDate: .now)
        session.endDate = .now
        session.passage = passage
        context.insert(session)

        let set = StudySet(name: "Favorites")
        set.passages = [passage]
        context.insert(set)
        try context.save()

        context.delete(passage)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<PracticeSession>()).isEmpty)
        let sets = try context.fetch(FetchDescriptor<StudySet>())
        #expect(sets.count == 1)
        #expect(sets.first?.passages?.isEmpty == true)
    }

    @Test func `deleting set leaves passages in library`() throws {
        let context = makeContext()
        let passage = try insertJohn316(context)
        let set = StudySet(name: "Doomed")
        set.passages = [passage]
        context.insert(set)
        try context.save()

        context.delete(set)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<StudySet>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Passage>()).count == 1)
    }

    @Test func `passage reference formatting`() {
        let single = Passage(book: "John", startChapter: 3, endChapter: 3, startVerse: 16, endVerse: 16)
        #expect(single.reference == "John 3:16")

        let range = Passage(book: "John", startChapter: 3, endChapter: 3, startVerse: 16, endVerse: 18)
        #expect(range.reference == "John 3:16-18")

        let crossChapter = Passage(book: "John", startChapter: 3, endChapter: 4, startVerse: 16, endVerse: 2)
        #expect(crossChapter.reference == "John 3:16-4:2")
    }
}
