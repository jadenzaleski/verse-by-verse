//
//  NotificationPlannerTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 11/2/26.
//

import Foundation
import Testing
@testable import VerseByVerse

/// What gets scheduled, with fixed dates in a fixed time zone. Monday
/// 2026-11-02 is the reference "today".
@MainActor
@Suite("Notification planner")
struct NotificationPlannerTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Mon 2026-11-02 08:00 UTC.
    private var now: Date {
        date(2026, 11, 2, 8)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func plan(
        _ preferences: NotificationPreferences,
        items: [DueItem] = [],
        practicedDays: Set<Date> = [],
        now: Date? = nil,
    ) -> NotificationPlan {
        NotificationPlanner.plan(
            preferences: preferences,
            items: items,
            practicedDays: practicedDays,
            now: now ?? self.now,
            calendar: calendar,
        )
    }

    private func notifications(_ plan: NotificationPlan, _ kind: PlannedNotification.Kind) -> [PlannedNotification] {
        plan.notifications.filter { $0.kind == kind }
    }

    private let dueNow = DueItem(label: "John 3:16", dueDate: .distantPast)

    // MARK: - Nothing enabled

    @Test func `nothing is scheduled and the badge is clear when everything is off`() {
        let result = plan(NotificationPreferences(), items: [dueNow])
        #expect(result.notifications.isEmpty)
        #expect(result.badgeNow == 0)
    }

    // MARK: - Daily reminder

    @Test func `a daily reminder is planned for each of the next two weeks while things are due`() {
        let result = plan(
            NotificationPreferences(dailyReminderEnabled: true, dailyReminderMinutes: 9 * 60),
            items: [dueNow],
        )
        let reminders = notifications(result, .dailyReminder)
        #expect(reminders.count == NotificationPlanner.horizonDays)
        #expect(reminders.first?.fireDate == date(2026, 11, 2, 9))
        #expect(reminders.last?.fireDate == date(2026, 11, 15, 9))
        #expect(reminders.allSatisfy { NotificationPlanner.dailyTitles.contains($0.title ?? "") })
        // Titles rotate through whatever the planner offers.
        #expect(Set(reminders.map(\.title)).count == NotificationPlanner.dailyTitles.count)
    }

    @Test func `todays reminder is skipped once its time has passed`() {
        let result = plan(
            NotificationPreferences(dailyReminderEnabled: true, dailyReminderMinutes: 9 * 60),
            items: [dueNow],
            now: date(2026, 11, 2, 10),
        )
        let reminders = notifications(result, .dailyReminder)
        #expect(reminders.first?.fireDate == date(2026, 11, 3, 9))
        #expect(reminders.count == NotificationPlanner.horizonDays - 1)
    }

    @Test func `todays reminder is skipped when todays practice is already done`() {
        let result = plan(
            NotificationPreferences(dailyReminderEnabled: true, dailyReminderMinutes: 9 * 60),
            items: [dueNow],
            practicedDays: [date(2026, 11, 2)],
        )
        #expect(notifications(result, .dailyReminder).first?.fireDate == date(2026, 11, 3, 9))
    }

    @Test func `days with nothing due get no reminder`() {
        // Due Thursday at noon: the 9:00 reminder that morning is too early.
        let item = DueItem(label: "Psalm 23", dueDate: date(2026, 11, 5, 12))
        let result = plan(
            NotificationPreferences(dailyReminderEnabled: true, dailyReminderMinutes: 9 * 60),
            items: [item],
        )
        let reminders = notifications(result, .dailyReminder)
        #expect(reminders.first?.fireDate == date(2026, 11, 6, 9))
        #expect(reminders.first?.body?.contains("Psalm 23") == true)
    }

    @Test func `the reminder counts what will be due by then`() {
        let items = [
            DueItem(label: "A", dueDate: .distantPast),
            DueItem(label: "B", dueDate: date(2026, 11, 3, 6)),
            DueItem(label: "C", dueDate: date(2026, 11, 4, 6)),
        ]
        let result = plan(
            NotificationPreferences(dailyReminderEnabled: true, dailyReminderMinutes: 9 * 60),
            items: items,
        )
        let bodies = notifications(result, .dailyReminder).prefix(3).compactMap(\.body)
        #expect(bodies.count == 3)
        #expect(bodies[0].contains("A"))
        #expect(bodies[1].contains("2"))
        #expect(bodies[2].contains("3"))
    }

    @Test func `with nothing ever due there are no reminders`() {
        let result = plan(NotificationPreferences(dailyReminderEnabled: true), items: [])
        #expect(result.notifications.isEmpty)
    }

    // MARK: - Streak reminder

    private var streakOn: NotificationPreferences {
        NotificationPreferences(streakReminderEnabled: true)
    }

    @Test func `a streak not yet practiced today is reminded tonight at eight`() {
        let result = plan(streakOn, practicedDays: [date(2026, 11, 1)])
        let reminder = notifications(result, .streakReminder)
        #expect(reminder.count == 1)
        #expect(reminder.first?.fireDate == date(2026, 11, 2, 20))
        #expect(reminder.first?.body?.contains("1-day streak") == true)
    }

    @Test func `once today is practiced the reminder moves to tomorrow night`() {
        let result = plan(streakOn, practicedDays: [date(2026, 10, 31), date(2026, 11, 1), date(2026, 11, 2)])
        let reminder = notifications(result, .streakReminder)
        #expect(reminder.count == 1)
        #expect(reminder.first?.fireDate == date(2026, 11, 3, 20))
        #expect(reminder.first?.body?.contains("3-day streak") == true)
    }

    @Test func `no streak means no streak reminder`() {
        // Last practiced three days ago: the streak is already over.
        #expect(plan(streakOn, practicedDays: [date(2026, 10, 30)]).notifications.isEmpty)
        #expect(plan(streakOn, practicedDays: []).notifications.isEmpty)
    }

    @Test func `too late tonight means no streak reminder`() {
        let result = plan(streakOn, practicedDays: [date(2026, 11, 1)], now: date(2026, 11, 2, 21))
        #expect(result.notifications.isEmpty)
    }

    // MARK: - Badge

    private var badgeOn: NotificationPreferences {
        NotificationPreferences(badgeEnabled: true)
    }

    @Test func `the badge shows how many are due right now`() {
        let items = [dueNow, dueNow, DueItem(label: "later", dueDate: date(2026, 11, 3))]
        #expect(plan(badgeOn, items: items).badgeNow == 2)
    }

    @Test func `silent badge updates are planned for when the count rises`() {
        let items = [
            dueNow,
            DueItem(label: "a", dueDate: date(2026, 11, 2, 9, 0)),
            DueItem(label: "b", dueDate: date(2026, 11, 2, 9, 5)), // same session as "a": merged
            DueItem(label: "c", dueDate: date(2026, 11, 5, 12)),
        ]
        let updates = notifications(plan(badgeOn, items: items), .badgeUpdate)
        #expect(updates.map(\.fireDate) == [date(2026, 11, 2, 9, 5), date(2026, 11, 5, 12)])
        #expect(updates.map(\.badge) == [3, 4])
        #expect(updates.allSatisfy { $0.title == nil && $0.body == nil })
    }

    @Test func `badge updates are capped so the total stays under the system limit`() {
        let items = (1 ... 80).map { DueItem(label: "v\($0)", dueDate: now.addingTimeInterval(Double($0) * 3600)) }
        let result = plan(
            NotificationPreferences(
                dailyReminderEnabled: true, streakReminderEnabled: true, badgeEnabled: true,
            ),
            items: items,
            practicedDays: [date(2026, 11, 1)],
        )
        #expect(notifications(result, .badgeUpdate).count == NotificationPlanner.maxBadgeUpdates)
        #expect(result.notifications.count < 64)
    }

    @Test func `the daily reminder carries the badge only when the badge is on`() {
        let withBadge = plan(
            NotificationPreferences(dailyReminderEnabled: true, badgeEnabled: true), items: [dueNow],
        )
        #expect(notifications(withBadge, .dailyReminder).first?.badge == 1)
        let withoutBadge = plan(NotificationPreferences(dailyReminderEnabled: true), items: [dueNow])
        #expect(notifications(withoutBadge, .dailyReminder).first?.badge == nil)
    }

    // MARK: - Housekeeping

    @Test func `every identifier is ours and unique, and the plan is in time order`() {
        let result = plan(
            NotificationPreferences(
                dailyReminderEnabled: true, streakReminderEnabled: true, badgeEnabled: true,
            ),
            items: [dueNow, DueItem(label: "x", dueDate: date(2026, 11, 4, 3))],
            practicedDays: [date(2026, 11, 1)],
        )
        let ids = result.notifications.map(\.identifier)
        #expect(ids.allSatisfy { $0.hasPrefix(NotificationPlanner.identifierPrefix) })
        #expect(Set(ids).count == ids.count)
        #expect(result.notifications.map(\.fireDate) == result.notifications.map(\.fireDate).sorted())
    }
}
