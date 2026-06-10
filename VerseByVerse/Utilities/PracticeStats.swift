//
//  PracticeStats.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/10/26.
//

import Foundation

/// Pure aggregate computations over a user's practice sessions.
///
/// Single source of truth for streak/score math shared between Home (current
/// streak) and Profile (lifetime stats). All functions consider only completed
/// sessions, keyed by the calendar day of `startDate`.
enum PracticeStats {
    /// Number of consecutive days, counting back from today, that contain a
    /// completed practice session. Returns 0 if today (and yesterday) have none.
    static func currentStreak(from sessions: [PracticeSession], calendar: Calendar = .current) -> Int {
        let days = completedDays(from: sessions, calendar: calendar)
        guard !days.isEmpty else { return 0 }

        var day = calendar.startOfDay(for: Date())
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
        let sortedDays = completedDays(from: sessions, calendar: calendar).sorted()
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
    private static func completedDays(from sessions: [PracticeSession], calendar: Calendar) -> Set<Date> {
        Set(sessions.filter(\.isCompleted).map { calendar.startOfDay(for: $0.startDate) })
    }
}
