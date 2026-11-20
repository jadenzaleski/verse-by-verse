//
//  MemoryScoreHistoryTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 11/18/26.
//

import Foundation
import SwiftData
import Testing
@testable import VerseByVerse

/// The passage History chart's score curve must be the same number the Memory
/// Score card shows (last result × retrievability, averaged over verses).
@MainActor
struct MemoryScoreHistoryTests {
    private let container = AppModelContainer.make(inMemory: true)
    private let scheduler = FSRSScheduler()
    private let epoch = Date(timeIntervalSince1970: 1_767_268_800) // 2026-01-01T12:00:00Z

    private func day(_ days: Double) -> Date {
        epoch.addingTimeInterval(days * 86400)
    }

    private func makeVerse(_ number: Int) throws -> Verse {
        try Verse.findOrCreate(
            translation: "KJV", book: "John", chapter: 3, number: number, in: container.mainContext,
        )
    }

    /// Mirrors the per-verse write path in `SessionView.completeSession`.
    @discardableResult
    private func practice(_ verse: Verse, score: Double, at date: Date) -> VerseReview {
        let outcome = scheduler.processReview(state: verse.memoryState, score: score, at: date)
        let review = VerseReview(reviewedAt: date)
        review.score = score
        review.rating = outcome.rating
        review.stabilityAfter = outcome.state.stability ?? 0
        review.difficultyAfter = outcome.state.difficulty ?? 0
        review.stateAfter = outcome.state.state
        review.verse = verse
        verse.memoryState = outcome.state
        return review
    }

    @Test func `chart and card agree`() throws {
        let context = container.mainContext
        let passage = Passage(book: "John", startChapter: 3, endChapter: 3, startVerse: 16, endVerse: 17)
        context.insert(passage)
        passage.verses = try [makeVerse(16), makeVerse(17)]
        // Only the first verse is practiced; the second counts as 0 in both.
        let first = try #require(passage.orderedVerses.first)
        practice(first, score: 0.76, at: epoch)
        try context.save()

        let snapshots = passage.orderedVerses.map(\.reviewSnapshots)
        for offset in [0.0, 2, 30] {
            let chart = MemoryScoreHistory.score(at: day(offset), verses: snapshots, scheduler: scheduler)
            let card = try #require(passage.memoryScore(using: scheduler, at: day(offset)))
            #expect(abs(chart - card) < 1e-9, "day \(offset): chart \(chart) vs card \(card)")
        }
    }

    @Test func `jumps to the new result at a review`() throws {
        let verse = try makeVerse(16)
        practice(verse, score: 0.5, at: day(0))
        practice(verse, score: 0.9, at: day(3))
        try container.mainContext.save()

        let points = MemoryScoreHistory.curve(
            from: day(0), to: day(10), verses: [verse.reviewSnapshots], scheduler: scheduler,
        )
        let atReview = try #require(points.first { $0.date == day(3) })
        #expect(abs(atReview.score - 0.9) < 1e-9)
        let justBefore = try #require(points.first { $0.date == day(3).addingTimeInterval(-1) })
        #expect(justBefore.score < 0.5)
    }

    @Test func `score before the first review is zero and clock skew is safe`() throws {
        let verse = try makeVerse(16)
        practice(verse, score: 0.5, at: day(1))
        practice(verse, score: 0.9, at: day(4))
        try container.mainContext.save()
        let snapshots = [verse.reviewSnapshots]

        #expect(MemoryScoreHistory.score(at: day(0), verses: snapshots, scheduler: scheduler) == 0)

        // An hour before the newest review only the older one counts.
        let skewed = MemoryScoreHistory.score(
            at: day(4).addingTimeInterval(-3600), verses: snapshots, scheduler: scheduler,
        )
        #expect(skewed <= 0.5 + 1e-12)
        #expect(skewed > 0)
    }

    @Test func `snapshots are ascending even when reviews are attached newest first`() throws {
        let verse = try makeVerse(16)
        let older = practice(verse, score: 0.5, at: day(0))
        let newer = practice(verse, score: 0.9, at: day(3))
        verse.reviews = [newer, older]
        try container.mainContext.save()

        #expect(verse.reviewSnapshots.map(\.reviewedAt) == [day(0), day(3)])
    }

    @Test func `curve dates strictly increase`() throws {
        let verse = try makeVerse(16)
        practice(verse, score: 0.8, at: day(0))
        practice(verse, score: 0.9, at: day(2)) // lands exactly on a grid date
        practice(verse, score: 0.95, at: day(3.5)) // between grid dates
        try container.mainContext.save()

        let points = MemoryScoreHistory.curve(
            from: day(0), to: day(7), verses: [verse.reviewSnapshots], sampleCount: 8, scheduler: scheduler,
        )
        let dates = points.map(\.date)
        #expect(zip(dates, dates.dropFirst()).allSatisfy { $0 < $1 })
        // 8 grid dates + 1 (day 2 − 1s; day 2 is already on the grid) + 2 (day 3.5 − 1s, day 3.5).
        #expect(points.count == 11)
        #expect(dates.first == day(0))
        #expect(dates.last == day(7))

        let empty = MemoryScoreHistory.curve(from: day(1), to: day(1), verses: [], scheduler: scheduler)
        #expect(empty.isEmpty)
    }

    @Test func `perfect results decay like retrievability`() throws {
        let verse = try makeVerse(16)
        practice(verse, score: 1.0, at: day(0))
        try container.mainContext.save()
        let state = verse.memoryState

        let points = MemoryScoreHistory.curve(
            from: day(0), to: day(30), verses: [verse.reviewSnapshots], scheduler: scheduler,
        )
        #expect(!points.isEmpty)
        for point in points {
            let recall = scheduler.retrievability(of: state, at: point.date)
            #expect(abs(point.score - recall) < 1e-9)
        }
    }
}
