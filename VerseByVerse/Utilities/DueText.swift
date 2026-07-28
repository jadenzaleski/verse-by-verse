//
//  DueText.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/27/26.
//

import Foundation

/// Formats how far away — or overdue — a next-practice date is, in one
/// consistent voice: "Due in N days" / "Due today" / "Overdue N days".
///
/// Single source of truth for due/overdue wording, shared between VerseCard,
/// PassageCard, PracticeCard, and HomeView's Up Next badges — previously
/// duplicated with drifting formats ("10d overdue", "Overdue by N days").
enum DueText {
    /// Calendar-day granularity between `now` and `date`.
    static func days(from now: Date = .now, to date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: now, to: date).day ?? 0
        if days > 0 { return "Due in \(pluralized(days, "day"))" }
        if days == 0 { return "Due today" }
        return "Overdue \(pluralized(-days, "day"))"
    }

    /// Same as `days`, but drops to hour/minute granularity once the
    /// difference is under a day — for contexts where sub-day precision
    /// matters (e.g. the practice card's countdown).
    static func precise(from now: Date = .now, to date: Date) -> String {
        if date <= now {
            let components = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: now)
            return largestUnit(components).map { "Overdue \(pluralized($0.count, $0.unit))" } ?? "Due now"
        }
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: date)
        return largestUnit(components).map { "Due in \(pluralized($0.count, $0.unit))" } ?? "Due now"
    }

    private static func largestUnit(_ components: DateComponents) -> (count: Int, unit: String)? {
        if let days = components.day, days > 0 { return (days, "day") }
        if let hours = components.hour, hours > 0 { return (hours, "hour") }
        if let minutes = components.minute, minutes > 0 { return (minutes, "minute") }
        return nil
    }

    private static func pluralized(_ count: Int, _ unit: String) -> String {
        "\(count) \(unit)\(count == 1 ? "" : "s")"
    }
}
