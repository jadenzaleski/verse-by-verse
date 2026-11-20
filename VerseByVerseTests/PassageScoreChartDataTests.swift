//
//  PassageScoreChartDataTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 11/19/26.
//

import Foundation
import Testing
@testable import VerseByVerse

/// The passage History chart's data — window, practice dots, curve, gradient and
/// drag-to-select — is plain values, so it is tested without a view or a store.
struct PassageScoreChartDataTests {
    private typealias ChartData = PassageScoreChartData<Int>

    private let scheduler = FSRSScheduler()
    private let epoch = Date(timeIntervalSince1970: 1_767_268_800) // 2026-01-01T12:00:00Z
    private let now: Date
    private let calendar: Calendar

    init() {
        now = epoch.addingTimeInterval(10 * 86400)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        self.calendar = calendar
    }

    private func day(_ days: Double) -> Date {
        epoch.addingTimeInterval(days * 86400)
    }

    /// One verse's review snapshots, replayed through the scheduler like a real history.
    private func snapshots(_ results: [(day: Double, score: Double)]) -> [ReviewSnapshot] {
        var state = MemoryState.new
        return results.map { result in
            let outcome = scheduler.processReview(state: state, score: result.score, at: day(result.day))
            state = outcome.state
            return ReviewSnapshot(
                reviewedAt: day(result.day),
                score: result.score,
                stability: outcome.state.stability ?? 0,
                difficulty: outcome.state.difficulty ?? 0,
                state: outcome.state.state,
            )
        }
    }

    private func session(_ id: Int, endingAt end: Date?, startingAt start: Date? = nil) -> ChartData.SessionInput {
        ChartData.SessionInput(id: id, startDate: start ?? (end ?? epoch).addingTimeInterval(-300), endDate: end)
    }

    private func makeData(
        _ duration: ChartDuration,
        sessions: [ChartData.SessionInput],
        verses: [[ReviewSnapshot]],
    ) -> ChartData {
        ChartData(
            duration: duration, now: now, calendar: calendar,
            sessions: sessions, snapshots: verses, scheduler: scheduler,
        )
    }

    @Test func `windows start back from now and All starts at the first session`() {
        #expect(ChartData.windowStart(for: .week, now: now, calendar: calendar, earliestSession: day(1)) == day(3))
        #expect(ChartData.windowStart(for: .all, now: now, calendar: calendar, earliestSession: day(1)) == day(1))
        #expect(ChartData.windowStart(for: .all, now: now, calendar: calendar, earliestSession: nil) == nil)
    }

    @Test func `practice dots sit on the curve inside the window, oldest first`() throws {
        let verses = [snapshots([(0, 0.5), (3, 0.9), (5, 0.7)])]
        // Out of order on purpose; the day-0 session is before the 1W window,
        // and the unfinished one is placed by its start date.
        let sessions = [
            session(3, endingAt: nil, startingAt: day(5)),
            session(1, endingAt: day(0)),
            session(2, endingAt: day(3)),
        ]
        let data = makeData(.week, sessions: sessions, verses: verses)

        #expect(data.markers.map(\.id) == [2, 3])
        for marker in data.markers {
            let onCurve = MemoryScoreHistory.score(at: marker.date, verses: verses, scheduler: scheduler)
            #expect(abs(marker.score - onCurve) < 1e-9)
        }
        let first = try #require(data.markers.first)
        #expect(abs(first.score - 0.9) < 1e-9) // the day-3 result, right after the review
    }

    @Test func `the curve starts at the first review and runs to now`() throws {
        let verses = [snapshots([(0, 0.8)])]
        let data = makeData(.year, sessions: [], verses: verses)

        #expect(data.rangeStart == day(0)) // the 1Y window reaches back before any practice
        #expect(data.curve.first?.date == day(0))
        #expect(data.curve.last?.date == now)
        let end = try #require(data.curve.last)
        #expect(abs(end.score - data.score(at: now)) < 1e-9)
    }

    @Test func `no reviews means no curve, no range and nothing to select`() {
        let data = makeData(.all, sessions: [session(1, endingAt: day(1))], verses: [[]])

        #expect(data.curve.isEmpty)
        #expect(data.rangeStart == nil)
        #expect(data.gradientSpan == nil)
        #expect(data.selection(at: day(5)) == nil)
    }

    @Test func `gradient follows a falling curve and is skipped for a flat one`() throws {
        let falling = makeData(.all, sessions: [], verses: [snapshots([(0, 0.9)])])
        let span = try #require(falling.gradientSpan)
        #expect(span.startY > span.endY)

        let flat = makeData(.all, sessions: [], verses: [snapshots([(0, 0.0)])]) // always 0%
        #expect(flat.gradientSpan == nil)
    }

    @Test func `dragging snaps to a nearby dot and otherwise follows the finger`() throws {
        let verses = [snapshots([(3, 0.9), (5, 0.7)])]
        let sessions = [session(1, endingAt: day(3)), session(2, endingAt: day(5))]
        let data = makeData(.week, sessions: sessions, verses: verses) // range day 3…10, snap ≈ 2h

        let near = try #require(data.selection(at: day(5).addingTimeInterval(3600)))
        guard case let .marker(marker) = near else {
            Issue.record("expected a dot, got \(near)")
            return
        }
        #expect(marker.id == 2)

        let far = try #require(data.selection(at: day(5).addingTimeInterval(86400)))
        guard case let .moment(date) = far else {
            Issue.record("expected a free position, got \(far)")
            return
        }
        #expect(date == day(6))

        // Past either end the position clamps to the curve.
        guard case let .moment(late) = try #require(data.selection(at: day(50))) else {
            Issue.record("expected a free position at the end")
            return
        }
        #expect(late == now)
        guard case let .marker(early) = try #require(data.selection(at: day(-50))) else {
            Issue.record("expected the first dot at the start")
            return
        }
        #expect(early.id == 1)
    }

    @Test func `score at a date is the history score`() {
        let verses = [snapshots([(0, 0.76)]), snapshots([(2, 1.0)])]
        let data = makeData(.all, sessions: [], verses: verses)

        for offset in [0.0, 2, 7] {
            let expected = MemoryScoreHistory.score(at: day(offset), verses: verses, scheduler: scheduler)
            #expect(abs(data.score(at: day(offset)) - expected) < 1e-9)
        }
    }
}
