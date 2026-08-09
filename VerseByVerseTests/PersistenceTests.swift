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

/// SwiftData layer tests against an in-memory container: shared verse cards,
/// the per-verse practice write path, derived passage values, and deletion/
/// orphan-sweep rules.
@MainActor
struct PersistenceTests {
    /// Retained for the lifetime of each test — a ModelContext must not outlive
    /// its container (SwiftData traps on insert/save if it does).
    private let container = AppModelContainer.make(inMemory: true)

    private func makeContext() -> ModelContext {
        container.mainContext
    }

    /// John 3:16-17 with its two shared verse cards attached.
    private func insertJohn316to17(_ context: ModelContext) throws -> Passage {
        let passage = Passage(book: "John", startChapter: 3, endChapter: 3, startVerse: 16, endVerse: 17)
        context.insert(passage)
        var members: [Verse] = []
        for number in 16 ... 17 {
            try members.append(Verse.findOrCreate(
                translation: "KJV", book: "John", chapter: 3, number: number, in: context,
            ))
        }
        passage.verses = members
        try context.save()
        return passage
    }

    // MARK: - Shared verse identity

    @Test func `overlapping passages share verse cards`() throws {
        let context = makeContext()
        let first = try insertJohn316to17(context)

        // Second passage overlapping verse 17 reuses the same card.
        let second = Passage(book: "John", startChapter: 3, endChapter: 3, startVerse: 17, endVerse: 18)
        context.insert(second)
        var members: [Verse] = []
        for number in 17 ... 18 {
            try members.append(Verse.findOrCreate(
                translation: "KJV", book: "John", chapter: 3, number: number, in: context,
            ))
        }
        second.verses = members
        try context.save()

        let allVerses = try context.fetch(FetchDescriptor<Verse>())
        #expect(allVerses.count == 3) // 16, 17, 18 — verse 17 shared

        let shared = try #require(try Verse.existing(
            translation: "KJV", book: "John", chapter: 3, number: 17, in: context,
        ))
        #expect(shared.passages?.count == 2)
        _ = first
    }

    @Test func `different translation is a different card`() throws {
        let context = makeContext()
        _ = try Verse.findOrCreate(translation: "KJV", book: "John", chapter: 3, number: 16, in: context)
        _ = try Verse.findOrCreate(translation: "NIV", book: "John", chapter: 3, number: 16, in: context)
        try context.save()
        #expect(try context.fetch(FetchDescriptor<Verse>()).count == 2)
    }

    // MARK: - Practice write path

    @Test func `session writes one verse review per verse with snapshots`() throws {
        let context = makeContext()
        let passage = try insertJohn316to17(context)
        let scheduler = FSRSScheduler()
        let reviewDate = Date(timeIntervalSince1970: 1_767_268_800)

        // Mirror SessionView.completeSession's write path.
        let session = PracticeSession(startDate: reviewDate.addingTimeInterval(-180))
        session.endDate = reviewDate
        session.score = 0.92
        session.rating = MemoryScoring.rating(forScore: 0.92)
        session.passage = passage
        for verse in passage.orderedVerses {
            let outcome = scheduler.processReview(state: verse.memoryState, score: 0.92, at: reviewDate)
            let review = VerseReview(reviewedAt: reviewDate)
            review.score = 0.92
            review.rating = outcome.rating
            review.stabilityAfter = outcome.state.stability ?? 0
            review.difficultyAfter = outcome.state.difficulty ?? 0
            review.stateAfter = outcome.state.state
            review.verse = verse
            review.session = session
            verse.memoryState = outcome.state
        }
        context.insert(session)
        try context.save()

        #expect(session.verseReviews?.count == 2)
        for verse in passage.orderedVerses {
            #expect(verse.reps == 1)
            #expect(verse.stability != nil)
            #expect(verse.nextPractice != nil)
            let review = try #require(verse.reviews?.first)
            #expect(review.rating == 3)
            #expect(review.stabilityAfter > 0)
        }
        // Derived passage values follow the verses.
        #expect(passage.totalReps == 2)
        #expect(passage.lastPracticed == reviewDate)
        #expect(passage.nextPractice != nil)
        #expect(!passage.isNew)
    }

    // MARK: - Derived aggregations

    @Test func `passage due and score derive from verses`() throws {
        let context = makeContext()
        let passage = try insertJohn316to17(context)
        let scheduler = FSRSScheduler()
        let now = Date()

        // New passage: due, new, no score yet.
        #expect(passage.isDue(at: now))
        #expect(passage.isNew)
        #expect(passage.memoryScore(using: scheduler, at: now) == nil)

        // Practice only the first verse.
        let verses = passage.orderedVerses
        let outcome = scheduler.processReview(state: verses[0].memoryState, score: 0.92, at: now)
        verses[0].memoryState = outcome.state
        try context.save()

        // Second verse still new → passage still due; due date = earliest scheduled.
        #expect(passage.isDue(at: now))
        #expect(passage.nextPractice == verses[0].nextPractice)

        // Score is the average across ALL verses (unpracticed counts as 0).
        let score = try #require(passage.memoryScore(using: scheduler, at: now))
        let firstR = scheduler.retrievability(of: verses[0].memoryState, at: now)
        #expect(abs(score - firstR / 2) < 0.0001)
    }

    // MARK: - Deletion & orphan sweep

    @Test func `deleting a passage sweeps only true orphans`() throws {
        let context = makeContext()
        let passage = try insertJohn316to17(context)

        // Verse 17 also lives in another passage; verse 16 is also added directly.
        let other = Passage(book: "John", startChapter: 3, endChapter: 3, startVerse: 17, endVerse: 18)
        context.insert(other)
        other.verses = try [17, 18].map {
            try Verse.findOrCreate(translation: "KJV", book: "John", chapter: 3, number: $0, in: context)
        }
        let sixteen = try #require(try Verse.existing(
            translation: "KJV", book: "John", chapter: 3, number: 16, in: context,
        ))
        sixteen.addedDirectly = true
        try context.save()

        context.delete(passage)
        try Verse.sweepOrphans(in: context)
        try context.save()

        // 16 survives (addedDirectly), 17 + 18 survive (other passage).
        let remaining = try context.fetch(FetchDescriptor<Verse>())
        #expect(Set(remaining.map(\.number)) == [16, 17, 18])

        // Now delete the other passage and un-mark 16: everything sweeps.
        sixteen.addedDirectly = false
        context.delete(other)
        try Verse.sweepOrphans(in: context)
        try context.save()
        #expect(try context.fetch(FetchDescriptor<Verse>()).isEmpty)
    }

    @Test func `deleting a verse that's in a passage deletes the passage and sweeps siblings`() throws {
        let context = makeContext()
        let passage = try insertJohn316to17(context)
        let target = try #require(try Verse.existing(
            translation: "KJV", book: "John", chapter: 3, number: 16, in: context,
        ))

        // Mirror VerseDetailView.deleteVerse(): remove set memberships (none here),
        // delete owning passages, clear addedDirectly, sweep.
        for set in target.studySets ?? [] {
            set.verses?.removeAll { $0 === target }
        }
        for owningPassage in target.passages ?? [] {
            context.delete(owningPassage)
        }
        target.addedDirectly = false
        try Verse.sweepOrphans(in: context)
        try context.save()

        // Passage and both its verses (16 had no other reference) are gone.
        #expect(try context.fetch(FetchDescriptor<Passage>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Verse>()).isEmpty)
        _ = passage
    }

    @Test func `deleting a verse that's only in sets removes it from every set`() throws {
        let context = makeContext()
        let verse = try Verse.findOrCreate(
            translation: "KJV", book: "Philippians", chapter: 4, number: 13, in: context,
        )
        verse.addedDirectly = true

        let setA = StudySet(name: "Set A")
        setA.verses = [verse]
        let setB = StudySet(name: "Set B")
        setB.verses = [verse]
        context.insert(setA)
        context.insert(setB)
        try context.save()
        #expect(verse.studySets?.count == 2)

        // Mirror VerseDetailView.deleteVerse(): remove from every set, no owning
        // passages, clear addedDirectly, sweep.
        for set in verse.studySets ?? [] {
            set.verses?.removeAll { $0 === verse }
        }
        for owningPassage in verse.passages ?? [] {
            context.delete(owningPassage)
        }
        verse.addedDirectly = false
        try Verse.sweepOrphans(in: context)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Verse>()).isEmpty)
        #expect(setA.verses?.isEmpty == true)
        #expect(setB.verses?.isEmpty == true)
    }

    @Test func `sweeping a verse cascades its reviews`() throws {
        let context = makeContext()
        let passage = try insertJohn316to17(context)
        let verse = passage.orderedVerses[0]

        let session = PracticeSession(startDate: .now)
        session.endDate = .now
        context.insert(session)
        let review = VerseReview(reviewedAt: .now)
        review.verse = verse
        review.session = session
        try context.save()
        #expect(try context.fetch(FetchDescriptor<VerseReview>()).count == 1)

        context.delete(passage)
        try Verse.sweepOrphans(in: context)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Verse>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<VerseReview>()).isEmpty)
    }

    @Test func `deleting a set leaves passages and verses in the library`() throws {
        let context = makeContext()
        let passage = try insertJohn316to17(context)
        let standalone = try Verse.findOrCreate(
            translation: "KJV", book: "Philippians", chapter: 4, number: 13, in: context,
        )
        standalone.addedDirectly = true

        let set = StudySet(name: "Doomed")
        set.passages = [passage]
        set.verses = [standalone]
        context.insert(set)
        try context.save()

        context.delete(set)
        try Verse.sweepOrphans(in: context)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<StudySet>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Passage>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Verse>()).count == 3) // 16, 17, standalone
    }

    // MARK: - Formatting

    @Test func `reference formatting`() {
        let single = Verse(book: "John", chapter: 3, number: 16)
        #expect(single.reference == "John 3:16")

        let range = Passage(book: "John", startChapter: 3, endChapter: 3, startVerse: 16, endVerse: 18)
        #expect(range.reference == "John 3:16-18")

        let crossChapter = Passage(book: "John", startChapter: 3, endChapter: 4, startVerse: 16, endVerse: 2)
        #expect(crossChapter.reference == "John 3:16-4:2")
    }
}
