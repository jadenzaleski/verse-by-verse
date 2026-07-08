//
//  FSRSSchedulerTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 7/7/26.
//

import Foundation
import Testing
@testable import VerseByVerse

/// Behavioral tests for the on-device FSRS engine (swift-fsrs, used out of
/// the box). These pin VBV's domain rules — score→rating thresholds,
/// reps/lapses counting, retrievability — not the library's internal math.
struct FSRSSchedulerTests {
    private let epoch = Date(timeIntervalSince1970: 1_767_268_800) // 2026-01-01T12:00:00Z

    @Test func `score to rating thresholds`() {
        #expect(MemoryScoring.rating(forScore: 0.95) == 4)
        #expect(MemoryScoring.rating(forScore: 0.90) == 4)
        #expect(MemoryScoring.rating(forScore: 0.89) == 3)
        #expect(MemoryScoring.rating(forScore: 0.80) == 3)
        #expect(MemoryScoring.rating(forScore: 0.79) == 2)
        #expect(MemoryScoring.rating(forScore: 0.60) == 2)
        #expect(MemoryScoring.rating(forScore: 0.59) == 1)
        #expect(MemoryScoring.rating(forScore: 0.0) == 1)
    }

    @Test func `first review schedules the future`() {
        let scheduler = FSRSScheduler()
        let outcome = scheduler.processReview(state: .new, score: 0.85, at: epoch)

        #expect(outcome.rating == 3)
        #expect(outcome.state.reps == 1)
        #expect(outcome.state.stability != nil)
        #expect(outcome.state.difficulty != nil)
        #expect(outcome.state.lastReviewed == epoch)
        let due = outcome.state.due
        #expect(due != nil && due! > epoch)
    }

    @Test func `good reviews grow the interval`() {
        let scheduler = FSRSScheduler()
        var state = MemoryState.new
        var previousInterval = 0.0

        // Practice at each due date; once in review state (2), intervals
        // should be spaced repetition — strictly growing under Good scores.
        for _ in 0 ..< 8 {
            let outcome = scheduler.processReview(state: state, score: 0.85, at: state.due ?? epoch)
            state = outcome.state
            if state.state == 2 {
                #expect(outcome.intervalDays >= previousInterval)
                previousInterval = outcome.intervalDays
            }
        }
        #expect(state.state == 2)
        #expect(previousInterval > 1, "review intervals should reach multiple days")
    }

    @Test func `failing A review shortens the schedule`() {
        let scheduler = FSRSScheduler()
        var state = MemoryState.new

        // Build up some stability first.
        for _ in 0 ..< 4 {
            state = scheduler.processReview(state: state, score: 0.9, at: state.due ?? epoch).state
        }
        let stabilityBefore = state.stability ?? 0

        let failed = scheduler.processReview(state: state, score: 0.2, at: state.due ?? epoch)
        #expect(failed.rating == 1)
        #expect((failed.state.stability ?? 0) < stabilityBefore)
    }

    @Test func `reps and lapses follow VBV spec`() {
        // Every review increments reps; every Again (score < 0.60) is a lapse.
        let scheduler = FSRSScheduler()
        var state = MemoryState.new
        var reviewDate = epoch

        for (index, score) in [0.85, 0.85, 0.30, 0.85, 0.10].enumerated() {
            let outcome = scheduler.processReview(state: state, score: score, at: reviewDate)
            state = outcome.state
            #expect(state.reps == index + 1)
            reviewDate = state.due ?? reviewDate.addingTimeInterval(86400)
        }
        #expect(state.lapses == 2)
    }

    @Test func `retrievability decays over time`() throws {
        let scheduler = FSRSScheduler()
        var state = MemoryState.new

        // Two reviews to graduate into review state with real stability.
        state = scheduler.processReview(state: state, score: 0.85, at: epoch).state
        let firstDue = try #require(state.due)
        state = scheduler.processReview(state: state, score: 0.85, at: firstDue).state

        let lastReviewed = try #require(state.lastReviewed)
        let due = try #require(state.due)
        let justAfter = scheduler.retrievability(of: state, at: lastReviewed)
        let atDue = scheduler.retrievability(of: state, at: due)
        let wayLater = scheduler.retrievability(of: state, at: due.addingTimeInterval(30 * 86400))

        #expect(justAfter > 0.98)
        // At the due date, retrievability should sit near the 0.9 target —
        // the property that makes the Memory Score meaningful.
        #expect(abs(atDue - 0.9) < 0.02, "retrievability at due was \(atDue)")
        #expect(wayLater < atDue)
        #expect(scheduler.retrievability(of: .new, at: epoch) == 0)
    }

    @Test func `scheduling is deterministic`() {
        // Fuzz is off: two devices replaying the same reviews must agree.
        let first = FSRSScheduler().processReview(state: .new, score: 0.85, at: epoch)
        let second = FSRSScheduler().processReview(state: .new, score: 0.85, at: epoch)
        #expect(first == second)
    }
}
