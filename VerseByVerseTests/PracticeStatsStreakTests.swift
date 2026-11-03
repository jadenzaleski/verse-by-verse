//
//  PracticeStatsStreakTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 11/2/26.
//

import Foundation
import Testing
@testable import VerseByVerse

/// The current streak survives until a whole day is missed: not having
/// practiced *yet* today doesn't end it.
@MainActor
@Suite("Practice streak")
struct PracticeStatsStreakTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func at(_ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    private func completed(_ day: Int) -> PracticeSession {
        let session = PracticeSession(startDate: at(day))
        session.endDate = at(day).addingTimeInterval(300)
        return session
    }

    private func streak(_ days: [Int], today: Int) -> Int {
        PracticeStats.currentStreak(from: days.map(completed), now: at(today, hour: 9), calendar: calendar)
    }

    @Test func `practicing today counts today`() {
        #expect(streak([1, 2, 3], today: 3) == 3)
    }

    @Test func `not practicing yet today keeps the streak alive through yesterday`() {
        #expect(streak([1, 2, 3], today: 4) == 3)
    }

    @Test func `a missed day ends the streak`() {
        #expect(streak([1, 2, 3], today: 5) == 0)
    }

    @Test func `gaps split streaks and only the latest run counts`() {
        #expect(streak([1, 2, 4, 5], today: 5) == 2)
    }

    @Test func `no sessions means no streak`() {
        #expect(streak([], today: 5) == 0)
    }

    @Test func `unfinished sessions do not count`() {
        let abandoned = PracticeSession(startDate: at(3))
        #expect(PracticeStats.currentStreak(from: [abandoned], now: at(3), calendar: calendar) == 0)
    }
}
