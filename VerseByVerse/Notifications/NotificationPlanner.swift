//
//  NotificationPlanner.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/2/26.
//

import Foundation

/// What the user turned on in Settings.
struct NotificationPreferences: Equatable {
    var dailyReminderEnabled = false
    /// Minutes after midnight, local time.
    var dailyReminderMinutes = NotificationPreferences.defaultDailyReminderMinutes
    var streakReminderEnabled = false
    var badgeEnabled = false

    static let defaultDailyReminderMinutes = 9 * 60
    /// The streak reminder is fixed at 8 PM: late enough that the day's
    /// practice is probably done if it's going to be, early enough to act on.
    static let streakReminderMinutes = 20 * 60

    var isAnythingEnabled: Bool {
        dailyReminderEnabled || streakReminderEnabled || badgeEnabled
    }
}

/// A passage, or a standalone verse, and when it next needs review. This is
/// exactly what Home counts as "due": a passage is due when any verse is.
struct DueItem: Equatable {
    var label: String
    /// When it becomes due. `.distantPast` for brand-new material, due now.
    var dueDate: Date
}

/// One local notification to hand to iOS.
struct PlannedNotification: Equatable {
    enum Kind: String {
        case dailyReminder
        case streakReminder
        /// Silent: carries only a badge number, to keep the icon count current
        /// while the app isn't running.
        case badgeUpdate
    }

    var identifier: String
    var kind: Kind
    var fireDate: Date
    var title: String?
    var body: String?
    var badge: Int?
}

/// The complete schedule for the next two weeks, plus the badge to show now.
struct NotificationPlan: Equatable {
    var notifications: [PlannedNotification]
    var badgeNow: Int
}

/// Decides what to schedule. Pure: everything it needs is passed in, so the
/// rules are testable with fixed dates.
///
/// Why a rolling plan: local notifications carry text fixed at scheduling
/// time and iOS keeps only the 64 soonest pending ones. So the plan covers
/// the next ``horizonDays`` days and is rebuilt whenever something changes
/// (launch, foreground, background, any save), keeping counts current.
enum NotificationPlanner {
    /// Every identifier we schedule starts with this, so we only ever remove our own.
    static let identifierPrefix = "vbv."
    static let horizonDays = 14
    /// 14 daily + 1 streak + 40 badge updates stays well under iOS's 64.
    static let maxBadgeUpdates = 40
    /// Due times this close together share one badge update.
    static let badgeCoalescingWindow: TimeInterval = 15 * 60

    static let dailyTitles = [
        "Your verses are ready for you!",
        "Time to review. You've got this!",
        "Have a few minutes to practice?",
    ]

    static func plan(
        preferences: NotificationPreferences,
        items: [DueItem],
        practicedDays: Set<Date>,
        now: Date,
        calendar: Calendar,
    ) -> NotificationPlan {
        let today = calendar.startOfDay(for: now)
        let practicedToday = practicedDays.contains(today)
        var notifications: [PlannedNotification] = []

        if preferences.dailyReminderEnabled {
            notifications += dailyReminders(
                preferences: preferences, items: items, practicedToday: practicedToday,
                today: today, now: now, calendar: calendar,
            )
        }
        if preferences.streakReminderEnabled,
           let streak = streakReminder(practicedDays: practicedDays, practicedToday: practicedToday,
                                       today: today, now: now, calendar: calendar)
        {
            notifications.append(streak)
        }
        if preferences.badgeEnabled {
            notifications += badgeUpdates(items: items, now: now)
        }

        notifications.sort { $0.fireDate < $1.fireDate }
        return NotificationPlan(
            notifications: notifications,
            badgeNow: preferences.badgeEnabled ? dueCount(items, at: now) : 0,
        )
    }

    static func dueCount(_ items: [DueItem], at date: Date) -> Int {
        items.count(where: { $0.dueDate <= date })
    }

    // MARK: - Daily reminder

    /// One reminder per day at the chosen time, but only when something will be
    /// due by then, and not today if today's practice is already done.
    private static func dailyReminders(
        preferences: NotificationPreferences,
        items: [DueItem],
        practicedToday: Bool,
        today: Date,
        now: Date,
        calendar: Calendar,
    ) -> [PlannedNotification] {
        (0 ..< horizonDays).compactMap { offset in
            guard !(offset == 0 && practicedToday),
                  let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let fire = time(preferences.dailyReminderMinutes, on: day, calendar: calendar),
                  fire > now
            else { return nil }

            let due = items.filter { $0.dueDate <= fire }
            guard !due.isEmpty else { return nil }
            return PlannedNotification(
                identifier: identifier(.dailyReminder, fire),
                kind: .dailyReminder,
                fireDate: fire,
                title: dailyTitle(on: day, calendar: calendar),
                body: due.count == 1
                    ? "\(due[0].label) is ready for you. A quick review keeps it fresh!"
                    : "\(due.count) reviews are ready for you. Let's go!",
                badge: preferences.badgeEnabled ? due.count : nil,
            )
        }
    }

    private static func dailyTitle(on day: Date, calendar: Calendar) -> String {
        let index = calendar.ordinality(of: .day, in: .era, for: day) ?? 0
        return dailyTitles[index % dailyTitles.count]
    }

    // MARK: - Streak reminder

    /// At most one pending at a time. A streak is only at risk on the first
    /// evening after the last practice day: tonight if you haven't practiced
    /// yet today, tomorrow night if you already have. Later evenings can't
    /// matter, because by then the streak would already have ended.
    private static func streakReminder(
        practicedDays: Set<Date>,
        practicedToday: Bool,
        today: Date,
        now: Date,
        calendar: Calendar,
    ) -> PlannedNotification? {
        let streak = PracticeStats.streak(in: practicedDays, now: now, calendar: calendar)
        guard streak > 0,
              let day = calendar.date(byAdding: .day, value: practicedToday ? 1 : 0, to: today),
              let fire = time(NotificationPreferences.streakReminderMinutes, on: day, calendar: calendar),
              fire > now
        else { return nil }

        return PlannedNotification(
            identifier: identifierPrefix + "streak",
            kind: .streakReminder,
            fireDate: fire,
            title: "Don't break your streak! \u{1F525}",
            body: "Your \(streak)-day streak ends tonight. A quick review keeps it going. You've got this!",
            badge: nil,
        )
    }

    // MARK: - Badge

    /// Silent notifications at the moments the due count rises, so the icon is
    /// right even if the app isn't opened. Due times within a few minutes of
    /// each other (one session's verses) are merged into one update.
    private static func badgeUpdates(items: [DueItem], now: Date) -> [PlannedNotification] {
        let horizon = now.addingTimeInterval(TimeInterval(horizonDays) * 24 * 60 * 60)
        let moments = Set(items.map(\.dueDate).filter { $0 > now && $0 <= horizon }).sorted()

        var groupEnds: [Date] = []
        var groupStart: Date?
        for moment in moments {
            if let start = groupStart, moment.timeIntervalSince(start) <= badgeCoalescingWindow {
                groupEnds[groupEnds.count - 1] = moment
            } else {
                groupStart = moment
                groupEnds.append(moment)
            }
        }

        return groupEnds.prefix(maxBadgeUpdates).map { fire in
            PlannedNotification(
                identifier: identifier(.badgeUpdate, fire),
                kind: .badgeUpdate,
                fireDate: fire,
                title: nil,
                body: nil,
                badge: dueCount(items, at: fire),
            )
        }
    }

    // MARK: - Helpers

    private static func time(_ minutes: Int, on day: Date, calendar: Calendar) -> Date? {
        calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day)
    }

    private static func identifier(_ kind: PlannedNotification.Kind, _ date: Date) -> String {
        "\(identifierPrefix)\(kind.rawValue).\(Int(date.timeIntervalSince1970))"
    }
}
