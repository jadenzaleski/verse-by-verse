//
//  PracticeStats.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/10/26.
//

import Foundation

/// Pure aggregate computations over a user's practice sessions.
///
/// All functions consider only completed sessions,
/// keyed by the calendar day of `startDate`.
enum PracticeStats {
    /// Number of consecutive days with a completed practice session, counting
    /// back from today. If today has no session *yet*, the streak is still alive
    /// through yesterday and counts from there; it is 0 only once a whole day
    /// has been missed.
    static func currentStreak(
        from sessions: [PracticeSession],
        now: Date = Date(),
        calendar: Calendar = .current,
    ) -> Int {
        streak(in: practiceDays(from: sessions, calendar: calendar), now: now, calendar: calendar)
    }

    /// ``currentStreak(from:now:calendar:)`` over precomputed practice days.
    static func streak(in days: Set<Date>, now: Date, calendar: Calendar) -> Int {
        var day = calendar.startOfDay(for: now)
        if !days.contains(day) {
            // Today may simply not have been practiced yet.
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        var streak = 0
        while days.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    /// Longest run of consecutive days containing a completed practice session,
    /// across the user's entire history.
    static func bestStreak(from sessions: [PracticeSession], calendar: Calendar = .current) -> Int {
        let sortedDays = practiceDays(from: sessions, calendar: calendar).sorted()
        guard !sortedDays.isEmpty else { return 0 }

        var best = 1
        var run = 1
        for index in 1 ..< sortedDays.count {
            let previous = sortedDays[index - 1]
            let current = sortedDays[index]
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previous), nextDay == current {
                run += 1
                best = max(best, run)
            } else {
                run = 1
            }
        }
        return best
    }

    /// Count of completed sessions.
    static func completedCount(_ sessions: [PracticeSession]) -> Int {
        sessions.filter(\.isCompleted).count
    }

    /// Average score across completed sessions that have a score, or `nil` if none.
    static func averageScore(_ sessions: [PracticeSession]) -> Double? {
        let scores = sessions.filter(\.isCompleted).compactMap(\.score)
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    /// The distinct calendar days (start-of-day) that have at least one completed session.
    static func practiceDays(from sessions: [PracticeSession], calendar: Calendar = .current) -> Set<Date> {
        Set(sessions.filter(\.isCompleted).map { calendar.startOfDay(for: $0.startDate) })
    }
}
