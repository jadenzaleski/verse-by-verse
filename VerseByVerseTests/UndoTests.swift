//
//  UndoTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 10/20/26.
//

import Foundation
import SwiftData
import Testing
@testable import VerseByVerse

/// `ModelContext` undo over the library's destructive operations (see
/// `Deletion.swift`): an *unsaved* delete of a passage / verse / set, including
/// the orphan-sweep cascade into `VerseReview` history, must be fully
/// restorable with `UndoManager.undo()`. Once saved, it must not be.
@MainActor
struct UndoTests {
    private let container = AppModelContainer.make(inMemory: true)
    private let undoManager = UndoManager()

    private func makeContext() -> ModelContext {
        let context = container.mainContext
        // No run loop turns in tests, so group explicitly instead of per-event.
        undoManager.groupsByEvent = false
        context.undoManager = undoManager
        return context
    }

    /// Performs `body` as one undo group, like a single user action.
    private func asAction(_ body: () throws -> Void) rethrows {
        undoManager.beginUndoGrouping()
        defer { undoManager.endUndoGrouping() }
        try body()
    }

    private struct Fixture {
        let passage: Passage
        let verses: [Verse]
        let set: StudySet
        let session: PracticeSession
        let stabilities: [Double]
    }

    /// John 3:16-17 (both verses reviewed once, FSRS state set), a study set
    /// holding the passage, and one completed session with a review per verse.
    /// Everything is saved so undo starts from a clean persisted baseline.
    private func makeFixture(in context: ModelContext) throws -> Fixture {
        let passage = Passage(book: "John", startChapter: 3, endChapter: 3, startVerse: 16, endVerse: 17)
        context.insert(passage)
        let verses = try (16 ... 17).map {
            try Verse.findOrCreate(translation: "KJV", book: "John", chapter: 3, number: $0, in: context)
        }
        passage.verses = verses

        let set = StudySet(name: "Favorites")
        set.passages = [passage]
        context.insert(set)

        let scheduler = FSRSScheduler()
        let date = Date(timeIntervalSince1970: 1_767_268_800)
        let session = PracticeSession(startDate: date.addingTimeInterval(-120))
        session.endDate = date
        session.passage = passage
        context.insert(session)
        for verse in verses {
            let outcome = scheduler.processReview(state: verse.memoryState, score: 0.92, at: date)
            verse.memoryState = outcome.state
            let review = VerseReview(reviewedAt: date)
            review.rating = outcome.rating
            review.stabilityAfter = outcome.state.stability ?? 0
            review.verse = verse
            review.session = session
        }
        try context.save()

        return Fixture(
            passage: passage,
            verses: verses,
            set: set,
            session: session,
            stabilities: verses.map { $0.stability ?? 0 },
        )
    }

    private struct Counts {
        let passages: Int
        let verses: Int
        let reviews: Int
        let sets: Int
        let sessions: Int
    }

    private func counts(_ context: ModelContext) throws -> Counts {
        try Counts(
            passages: context.fetchCount(FetchDescriptor<Passage>()),
            verses: context.fetchCount(FetchDescriptor<Verse>()),
            reviews: context.fetchCount(FetchDescriptor<VerseReview>()),
            sets: context.fetchCount(FetchDescriptor<StudySet>()),
            sessions: context.fetchCount(FetchDescriptor<PracticeSession>()),
        )
    }

    /// Asserts the fixture graph is intact: rows, relationships, and FSRS state.
    private func expectRestored(_ fixture: Fixture, in context: ModelContext) throws {
        let all = try counts(context)
        #expect(all.passages == 1)
        #expect(all.verses == 2)
        #expect(all.reviews == 2)
        #expect(all.sets == 1)
        #expect(all.sessions == 1)

        let passage = try #require(try context.fetch(FetchDescriptor<Passage>()).first)
        #expect(Set(passage.orderedVerses.map(\.number)) == [16, 17])
        #expect(passage.studySets?.count == 1)
        #expect(passage.sessions?.count == 1)

        let set = try #require(try context.fetch(FetchDescriptor<StudySet>()).first)
        #expect(set.passages?.count == 1)

        for (verse, stability) in zip(passage.orderedVerses, fixture.stabilities) {
            #expect(verse.reps == 1)
            #expect(verse.stability == stability)
            #expect(verse.reviews?.count == 1)
            #expect(verse.reviews?.first?.session != nil)
            #expect(verse.passages?.count == 1)
        }
    }

    // MARK: - Unsaved delete → undo

    @Test func `undo restores a deleted passage and its verses and reviews`() throws {
        let context = makeContext()
        let fixture = try makeFixture(in: context)

        try asAction {
            try fixture.passage.delete(alsoDeleteVerses: true, in: context)
        }
        let afterDelete = try counts(context)
        #expect(afterDelete.passages == 0)
        #expect(afterDelete.verses == 0)
        #expect(afterDelete.reviews == 0) // cascaded with the verses
        #expect(undoManager.canUndo)

        undoManager.undo()
        try expectRestored(fixture, in: context)

        // Restored state must also persist cleanly.
        try context.save()
        try expectRestored(fixture, in: context)
    }

    @Test func `undo restores a deleted verse together with its owning passage`() throws {
        let context = makeContext()
        let fixture = try makeFixture(in: context)

        try asAction {
            try fixture.verses[0].deleteFromLibrary(in: context)
        }
        #expect(try counts(context).verses == 0)

        undoManager.undo()
        try expectRestored(fixture, in: context)
    }

    @Test func `undo restores a deleted set without touching its passages`() throws {
        let context = makeContext()
        let fixture = try makeFixture(in: context)

        try asAction {
            try fixture.set.delete(in: context)
        }
        #expect(try counts(context).sets == 0)
        #expect(try counts(context).passages == 1)

        undoManager.undo()
        try expectRestored(fixture, in: context)
    }

    @Test func `undo restores a passage-only delete that keeps its verses`() throws {
        let context = makeContext()
        let fixture = try makeFixture(in: context)

        try asAction {
            try fixture.passage.delete(alsoDeleteVerses: false, in: context)
        }
        #expect(try counts(context).passages == 0)
        #expect(try counts(context).verses == 2)

        undoManager.undo()
        try expectRestored(fixture, in: context)
        #expect(fixture.verses.allSatisfy { !$0.addedDirectly })
    }

    @Test func `redo re-applies the delete`() throws {
        let context = makeContext()
        let fixture = try makeFixture(in: context)

        try asAction {
            try fixture.passage.delete(alsoDeleteVerses: true, in: context)
        }
        undoManager.undo()
        #expect(undoManager.canRedo)
        undoManager.redo()

        let all = try counts(context)
        #expect(all.passages == 0)
        #expect(all.verses == 0)
        #expect(all.reviews == 0)
    }

    // MARK: - Saved delete → undo

    /// Documents the constraint the app's current flows hit: they save right
    /// after deleting, which is what the undo window is measured against.
    @Test func `undo after a save does not bring a deleted passage back`() throws {
        let context = makeContext()
        let fixture = try makeFixture(in: context)

        try asAction {
            try fixture.passage.delete(alsoDeleteVerses: true, in: context)
        }
        try context.save()

        undoManager.undo()
        try context.save()

        let all = try counts(context)
        #expect(all.passages == 0)
        #expect(all.verses == 0)
        #expect(all.reviews == 0)
    }
}
