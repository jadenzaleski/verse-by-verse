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
        #expect(MemoryScoring.rating(forScore: 1.0) == 4)
        #expect(MemoryScoring.rating(forScore: 0.99) == 4)
        #expect(MemoryScoring.rating(forScore: 0.98) == 3)
        #expect(MemoryScoring.rating(forScore: 0.90) == 3)
        #expect(MemoryScoring.rating(forScore: 0.89) == 2)
        #expect(MemoryScoring.rating(forScore: 0.70) == 2)
        #expect(MemoryScoring.rating(forScore: 0.69) == 1)
        #expect(MemoryScoring.rating(forScore: 0.0) == 1)
    }

    @Test func `verse with no scored words has no score`() {
        // Skipped, not failed: nil score means no review and no lapse.
        #expect(MemoryScoring.score(correct: 0, total: 0) == nil)
        #expect(MemoryScoring.score(correct: 0, total: 5) == 0)
        #expect(MemoryScoring.score(correct: 3, total: 4) == 0.75)
    }

    @Test func `first review schedules the future`() throws {
        let scheduler = FSRSScheduler()
        let outcome = scheduler.processReview(state: .new, score: 0.92, at: epoch)

        #expect(outcome.rating == 3)
        #expect(outcome.state.reps == 1)
        #expect(outcome.state.stability != nil)
        #expect(outcome.state.difficulty != nil)
        #expect(outcome.state.lastReviewed == epoch)
        let due = outcome.state.due
        #expect(try due != nil && #require(due) > epoch)
    }

    @Test func `good reviews grow the interval`() {
        let scheduler = FSRSScheduler()
        var state = MemoryState.new
        var previousInterval = 0.0

        // Practice at each due date; once in review state (2), intervals
        // should be spaced repetition — strictly growing under Good scores.
        for _ in 0 ..< 8 {
            let outcome = scheduler.processReview(state: state, score: 0.92, at: state.due ?? epoch)
            state = outcome.state
            if state.state == 2 {
                #expect(outcome.intervalDays >= previousInterval)
                previousInterval = outcome.intervalDays
            }
        }
        #expect(state.state == 2)
        #expect(previousInterval > 1, "review intervals should reach multiple days")
    }

    @Test func `intervals never exceed the 30 day cap`() {
        let scheduler = FSRSScheduler()
        var state = MemoryState.new
        var longest = 0.0

        // Perfect practice on every due date would otherwise reach hundreds of days.
        for _ in 0 ..< 12 {
            let outcome = scheduler.processReview(state: state, score: 1.0, at: state.due ?? epoch)
            state = outcome.state
            longest = max(longest, outcome.intervalDays)
            #expect(outcome.intervalDays <= FSRSScheduler.maximumIntervalDays + 1e-6)
        }
        #expect(abs(longest - FSRSScheduler.maximumIntervalDays) < 1e-6, "a well-known verse should reach the cap")
    }

    @Test func `failing A review shortens the schedule`() {
        let scheduler = FSRSScheduler()
        var state = MemoryState.new

        // Build up some stability first.
        for _ in 0 ..< 4 {
            state = scheduler.processReview(state: state, score: 0.92, at: state.due ?? epoch).state
        }
        let stabilityBefore = state.stability ?? 0

        let failed = scheduler.processReview(state: state, score: 0.2, at: state.due ?? epoch)
        #expect(failed.rating == 1)
        #expect((failed.state.stability ?? 0) < stabilityBefore)
    }

    @Test func `reps and lapses follow VBV spec`() {
        // Every review increments reps; every Again (score < 0.70) is a lapse.
        let scheduler = FSRSScheduler()
        var state = MemoryState.new
        var reviewDate = epoch

        for (index, score) in [0.92, 0.92, 0.30, 0.92, 0.10].enumerated() {
            let outcome = scheduler.processReview(state: state, score: score, at: reviewDate)
            state = outcome.state
            #expect(state.reps == index + 1)
            reviewDate = state.due ?? reviewDate.addingTimeInterval(86400)
        }
        #expect(state.lapses == 2)
    }

    @Test func `retrievability decays over time`() throws {
        // Explicit retention so the test states its own target.
        let target = 0.95
        let scheduler = FSRSScheduler(desiredRetention: target)
        var state = MemoryState.new

        // Two reviews to graduate into review state with real stability.
        state = scheduler.processReview(state: state, score: 0.92, at: epoch).state
        let firstDue = try #require(state.due)
        state = scheduler.processReview(state: state, score: 0.92, at: firstDue).state

        let lastReviewed = try #require(state.lastReviewed)
        let due = try #require(state.due)
        let justAfter = scheduler.retrievability(of: state, at: lastReviewed)
        let atDue = scheduler.retrievability(of: state, at: due)
        let wayLater = scheduler.retrievability(of: state, at: due.addingTimeInterval(30 * 86400))

        #expect(justAfter > 0.98)
        // At the due date, retrievability should sit near the retention target —
        // the property that makes the Memory Score meaningful.
        #expect(abs(atDue - target) < 0.02, "retrievability at due was \(atDue)")
        #expect(wayLater < atDue)
        #expect(scheduler.retrievability(of: .new, at: epoch) == 0)
    }

    @Test func `retrievability falls smoothly within a day`() {
        // The library floors elapsed time to whole days, which draws a staircase.
        let scheduler = FSRSScheduler()
        let state = scheduler.processReview(state: .new, score: 0.92, at: epoch).state

        var previous = scheduler.retrievability(of: state, at: epoch)
        for hour in 1 ... 72 {
            let value = scheduler.retrievability(of: state, at: epoch.addingTimeInterval(Double(hour) * 3600))
            #expect(value < previous, "flat or rising at hour \(hour): \(value) after \(previous)")
            previous = value
        }
    }

    @Test func `a state with no stability recalls nothing and is never NaN`() {
        let scheduler = FSRSScheduler()
        let reviewed = scheduler.processReview(state: .new, score: 0.92, at: epoch).state

        for stability in [0.0, -1.0, nil] {
            var state = reviewed
            state.stability = stability
            // Same instant as the review (elapsed 0) is the 0 ÷ 0 case; later is x ÷ 0.
            for offset in [0, 3] {
                let recall = scheduler.retrievability(of: state, at: epoch.addingTimeInterval(Double(offset) * 86400))
                #expect(recall == 0, "stability \(String(describing: stability)), day \(offset): \(recall)")
            }
        }
    }

    @Test func `first review schedules days out, never minutes`() {
        // A session already drills the passage; no minute-scale learning steps.
        let scheduler = FSRSScheduler()
        for score in [0.0, 0.75, 0.92, 1.0] {
            let outcome = scheduler.processReview(state: .new, score: score, at: epoch)
            #expect(outcome.state.state == 2, "score \(score) should land in review state")
            #expect(outcome.intervalDays >= 1, "score \(score) scheduled \(outcome.intervalDays) days out")
        }
    }

    @Test func `scheduling is deterministic`() {
        // Fuzz is off: two devices replaying the same reviews must agree.
        let first = FSRSScheduler().processReview(state: .new, score: 0.92, at: epoch)
        let second = FSRSScheduler().processReview(state: .new, score: 0.92, at: epoch)
        #expect(first == second)
    }

    // MARK: - Memory Score (last result × retrievability)

    private func day(_ days: Int) -> Date {
        epoch.addingTimeInterval(Double(days) * 86400)
    }

    @Test func `memory score starts at the result`() {
        let scheduler = FSRSScheduler()
        let state = scheduler.processReview(state: .new, score: 0.76, at: epoch).state
        let score = scheduler.memoryScore(of: state, lastResult: 0.76, at: epoch)
        #expect(abs(score - 0.76) < 1e-9)
    }

    @Test func `memory score only falls between reviews`() {
        let scheduler = FSRSScheduler()
        let state = scheduler.processReview(state: .new, score: 0.76, at: epoch).state
        var previous = 1.0
        for offset in 0 ... 60 {
            let value = scheduler.memoryScore(of: state, lastResult: 0.76, at: day(offset))
            #expect(value <= previous + 1e-12, "score rose on day \(offset)")
            previous = value
        }
        // A single 76% review reads about 61% four days later.
        let dayFour = scheduler.memoryScore(of: state, lastResult: 0.76, at: day(4))
        #expect((0.60 ... 0.63).contains(dayFour), "day-4 score was \(dayFour)")
    }

    @Test func `perfect result equals retrievability`() {
        let scheduler = FSRSScheduler()
        let state = scheduler.processReview(state: .new, score: 1.0, at: epoch).state
        for offset in [0, 4, 30] {
            let score = scheduler.memoryScore(of: state, lastResult: 1.0, at: day(offset))
            let recall = scheduler.retrievability(of: state, at: day(offset))
            #expect(abs(score - recall) < 1e-12)
        }
    }

    @Test func `no recorded result falls back to retrievability`() {
        let scheduler = FSRSScheduler()
        let state = scheduler.processReview(state: .new, score: 0.92, at: epoch).state
        let score = scheduler.memoryScore(of: state, lastResult: nil, at: day(5))
        #expect(score == scheduler.retrievability(of: state, at: day(5)))
    }

    @Test func `zero result scores zero and out of range results are clamped`() {
        let scheduler = FSRSScheduler()
        let state = scheduler.processReview(state: .new, score: 0.92, at: epoch).state
        #expect(scheduler.memoryScore(of: state, lastResult: 0, at: epoch) == 0)
        #expect(scheduler.memoryScore(of: state, lastResult: -0.2, at: epoch) == 0)
        let recall = scheduler.retrievability(of: state, at: day(3))
        #expect(scheduler.memoryScore(of: state, lastResult: 1.5, at: day(3)) == recall)
    }

    @Test func `unpracticed state scores zero`() {
        let scheduler = FSRSScheduler()
        #expect(scheduler.memoryScore(of: .new, lastResult: 0.9, at: epoch) == 0)
    }
}
