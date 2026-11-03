//
//  NotificationSchedulerTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 11/2/26.
//

import Foundation
import SwiftData
import Testing
import UserNotifications
@testable import VerseByVerse

/// A notification center that records what it is asked to do.
@MainActor
private final class FakeCenter: NotificationCenterProviding {
    var status: UNAuthorizationStatus = .notDetermined
    var grantsPermission = true
    private(set) var permissionRequests = 0
    private(set) var scheduled: [PlannedNotification] = []
    private(set) var replaceCalls = 0
    private(set) var badge: Int?
    private(set) var deliveredCleared = 0

    func authorizationStatus() async -> UNAuthorizationStatus {
        status
    }

    func requestAuthorization() async -> Bool {
        permissionRequests += 1
        status = grantsPermission ? .authorized : .denied
        return grantsPermission
    }

    func replaceScheduled(with notifications: [PlannedNotification]) async {
        replaceCalls += 1
        scheduled = notifications
    }

    func setBadgeCount(_ count: Int) async {
        badge = count
    }

    func removeDelivered() async {
        deliveredCleared += 1
    }
}

@MainActor
@Suite("Notification scheduler")
struct NotificationSchedulerTests {
    private let container = AppModelContainer.make(inMemory: true)
    private let center = FakeCenter()
    private let defaults: UserDefaults
    private let scheduler: NotificationScheduler

    init() {
        let suite = "vbv-notification-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        scheduler = NotificationScheduler(center: center, defaults: defaults)
        scheduler.configure(context: container.mainContext)
    }

    private func enable(daily: Bool = false, streak: Bool = false, badge: Bool = false) {
        defaults.set(daily, forKey: StorageKeys.dailyReminderEnabled.rawValue)
        defaults.set(streak, forKey: StorageKeys.streakReminderEnabled.rawValue)
        defaults.set(badge, forKey: StorageKeys.dueBadgeEnabled.rawValue)
    }

    private func addNewPassage() throws {
        let context = container.mainContext
        let passage = Passage(book: "John", startChapter: 3, endChapter: 3, startVerse: 16, endVerse: 17)
        context.insert(passage)
        passage.verses = try (16 ... 17).map {
            try Verse.findOrCreate(translation: "KJV", book: "John", chapter: 3, number: $0, in: context)
        }
        try context.save()
    }

    // MARK: - Permission

    @Test func `permission is requested the first time and not again once decided`() async {
        #expect(await scheduler.requestAuthorizationIfNeeded())
        #expect(center.permissionRequests == 1)
        #expect(await scheduler.requestAuthorizationIfNeeded())
        #expect(center.permissionRequests == 1)
    }

    @Test func `a denial is reported and never re-prompted`() async {
        center.grantsPermission = false
        #expect(await !scheduler.requestAuthorizationIfNeeded())
        #expect(await !scheduler.requestAuthorizationIfNeeded())
        #expect(center.permissionRequests == 1)
        #expect(scheduler.authorization == .denied)
    }

    // MARK: - Refresh

    @Test func `nothing is scheduled and the badge is cleared without permission`() async throws {
        try addNewPassage()
        enable(daily: true, badge: true)
        scheduler.refresh()
        await scheduler.waitForPendingWork()
        #expect(center.scheduled.isEmpty)
        #expect(center.badge == 0)
    }

    @Test func `the badge matches what Home counts as due`() async throws {
        center.status = .authorized
        await scheduler.refreshAuthorizationStatus()
        enable(badge: true)
        try addNewPassage() // new material is due immediately
        let standalone = try Verse.findOrCreate(
            translation: "KJV", book: "Psalms", chapter: 23, number: 1, in: container.mainContext,
        )
        standalone.addedDirectly = true
        try container.mainContext.save()

        scheduler.refresh()
        await scheduler.waitForPendingWork()
        // One due passage plus one due standalone verse; the passage's own
        // verses are not counted again.
        #expect(center.badge == 2)
    }

    @Test func `practiced material is not counted until it comes due`() async throws {
        center.status = .authorized
        await scheduler.refreshAuthorizationStatus()
        enable(badge: true)
        try addNewPassage()
        for verse in try container.mainContext.fetch(FetchDescriptor<Verse>()) {
            verse.reps = 1
            verse.nextPractice = Date.now.addingTimeInterval(3 * 24 * 3600)
        }
        try container.mainContext.save()

        scheduler.refresh()
        await scheduler.waitForPendingWork()
        #expect(center.badge == 0)
        // …but a silent update is planned for when it comes due.
        #expect(center.scheduled.contains { $0.kind == .badgeUpdate && $0.badge == 1 })
    }

    @Test func `turning everything off clears what was scheduled`() async throws {
        center.status = .authorized
        await scheduler.refreshAuthorizationStatus()
        try addNewPassage()
        enable(daily: true, badge: true)
        scheduler.refresh()
        await scheduler.waitForPendingWork()
        #expect(!center.scheduled.isEmpty)

        enable()
        scheduler.refresh()
        await scheduler.waitForPendingWork()
        #expect(center.scheduled.isEmpty)
        #expect(center.badge == 0)
    }

    @Test func `overlapping refreshes apply in order`() async throws {
        center.status = .authorized
        await scheduler.refreshAuthorizationStatus()
        try addNewPassage()
        enable(badge: true)
        scheduler.refresh()
        enable()
        scheduler.refresh()
        await scheduler.waitForPendingWork()
        #expect(center.replaceCalls == 2)
        #expect(center.badge == 0) // the later, "off" state wins
    }

    @Test func `coming to the foreground clears delivered banners`() async {
        scheduler.appBecameActive()
        // The work is queued on a task; give it a turn to run.
        try? await Task.sleep(for: .milliseconds(100))
        #expect(center.deliveredCleared == 1)
    }

    // MARK: - Preferences

    @Test func `preferences read the stored settings with sensible defaults`() {
        #expect(scheduler.preferences == NotificationPreferences())
        defaults.set(true, forKey: StorageKeys.dailyReminderEnabled.rawValue)
        defaults.set(19 * 60 + 30, forKey: StorageKeys.dailyReminderMinutes.rawValue)
        #expect(scheduler.preferences.dailyReminderEnabled)
        #expect(scheduler.preferences.dailyReminderMinutes == 19 * 60 + 30)
    }
}

// MARK: - First-session offer

extension NotificationSchedulerTests {
    @Test func `finishing a session asks once and a yes turns the daily reminder on`() async {
        await scheduler.offerRemindersAfterSession()
        #expect(center.permissionRequests == 1)
        #expect(scheduler.preferences.dailyReminderEnabled)

        await scheduler.offerRemindersAfterSession()
        #expect(center.permissionRequests == 1) // never asks twice
    }

    @Test func `a no leaves every reminder off and is not asked again`() async {
        center.grantsPermission = false
        await scheduler.offerRemindersAfterSession()
        #expect(!scheduler.preferences.dailyReminderEnabled)

        await scheduler.offerRemindersAfterSession()
        #expect(center.permissionRequests == 1)
    }

    @Test func `already decided users are left alone`() async {
        center.status = .denied
        await scheduler.offerRemindersAfterSession()
        #expect(center.permissionRequests == 0)
        #expect(!scheduler.preferences.dailyReminderEnabled)
    }
}
