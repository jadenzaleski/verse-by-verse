//
//  NotificationScheduler.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/2/26.
//

import Foundation
import Observation
import SwiftData
import UserNotifications

/// The slice of `UNUserNotificationCenter` the scheduler uses, so tests can
/// substitute a fake.
protocol NotificationCenterProviding {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async -> Bool
    /// Removes every pending notification this app scheduled and adds `notifications`.
    func replaceScheduled(with notifications: [PlannedNotification]) async
    func setBadgeCount(_ count: Int) async
    func removeDelivered() async
}

/// The real thing.
struct SystemNotificationCenter: NotificationCenterProviding {
    private let log = AppLog.category("Notifications")

    private var center: UNUserNotificationCenter {
        .current()
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            log.error("Notification authorization failed: \(error)")
            return false
        }
    }

    func replaceScheduled(with notifications: [PlannedNotification]) async {
        let pending = await center.pendingNotificationRequests().map(\.identifier)
        center.removePendingNotificationRequests(
            withIdentifiers: pending.filter { $0.hasPrefix(NotificationPlanner.identifierPrefix) },
        )
        for notification in notifications {
            do {
                try await center.add(request(for: notification))
            } catch {
                log.error("Could not schedule \(notification.kind.rawValue): \(error)")
            }
        }
    }

    func setBadgeCount(_ count: Int) async {
        do {
            try await center.setBadgeCount(count)
        } catch {
            log.error("Could not set the badge: \(error)")
        }
    }

    func removeDelivered() async {
        center.removeAllDeliveredNotifications()
    }

    private func request(for notification: PlannedNotification) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        if let title = notification.title {
            content.title = title
        }
        if let body = notification.body {
            content.body = body
            content.sound = .default
            content.threadIdentifier = "reminders"
        }
        if let badge = notification.badge {
            content.badge = NSNumber(value: badge)
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: notification.fireDate,
        )
        return UNNotificationRequest(
            identifier: notification.identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false),
        )
    }
}

/// Keeps the scheduled reminders, and the icon badge, matched to the library.
///
/// Call ``refresh()`` whenever something that affects them might have changed.
/// It is cheap, snapshots the library immediately, and applies the result in
/// order, so overlapping calls can't interleave. The app calls it at launch, on
/// foreground and background, after any SwiftData save (debounced), and when a
/// setting changes.
@MainActor
@Observable
final class NotificationScheduler {
    static let shared = NotificationScheduler()

    /// What iOS currently allows. Settings reads it to explain a denial.
    private(set) var authorization: UNAuthorizationStatus = .notDetermined

    private let center: NotificationCenterProviding
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let log = AppLog.category("Notifications")

    @ObservationIgnored private var context: ModelContext?
    @ObservationIgnored private var applyChain: Task<Void, Never>?
    @ObservationIgnored private var debounce: Task<Void, Never>?
    @ObservationIgnored private var saveObserver: NSObjectProtocol?

    /// - Parameter center: `nil` uses the real notification center; tests pass a fake.
    init(
        center: NotificationCenterProviding? = nil,
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current,
    ) {
        self.center = center ?? SystemNotificationCenter()
        self.defaults = defaults
        self.calendar = calendar
    }

    /// Connects the scheduler to the library and starts watching for saves.
    func configure(context: ModelContext) {
        self.context = context
        guard saveObserver == nil else { return }
        saveObserver = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave, object: nil, queue: .main,
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshSoon() }
        }
    }

    var preferences: NotificationPreferences {
        NotificationPreferences(
            dailyReminderEnabled: defaults.bool(forKey: StorageKeys.dailyReminderEnabled.rawValue),
            dailyReminderMinutes: defaults.object(forKey: StorageKeys.dailyReminderMinutes.rawValue) as? Int
                ?? NotificationPreferences.defaultDailyReminderMinutes,
            streakReminderEnabled: defaults.bool(forKey: StorageKeys.streakReminderEnabled.rawValue),
            badgeEnabled: defaults.bool(forKey: StorageKeys.dueBadgeEnabled.rawValue),
        )
    }

    // MARK: - Permission

    func refreshAuthorizationStatus() async {
        authorization = await center.authorizationStatus()
    }

    /// Asks the system for permission the first time; afterwards just reports
    /// whether it was granted. iOS only ever shows the prompt once.
    func requestAuthorizationIfNeeded() async -> Bool {
        await refreshAuthorizationStatus()
        if authorization == .notDetermined {
            _ = await center.requestAuthorization()
            await refreshAuthorizationStatus()
        }
        return isAuthorized
    }

    /// Called when the person finishes their first session: the one moment a
    /// reminder makes obvious sense. Asks only while iOS has never been asked,
    /// so it can't nag, and a yes turns the daily reminder on (at the default
    /// time; Settings changes it). A no leaves everything off.
    func offerRemindersAfterSession() async {
        await refreshAuthorizationStatus()
        guard authorization == .notDetermined else { return }
        if await requestAuthorizationIfNeeded() {
            defaults.set(true, forKey: StorageKeys.dailyReminderEnabled.rawValue)
            log.info("Reminders: allowed after first session, daily reminder on")
        } else {
            log.info("Reminders: declined after first session")
        }
        refresh()
    }

    var isAuthorized: Bool {
        switch authorization {
        case .authorized, .provisional, .ephemeral: true
        default: false
        }
    }

    // MARK: - Scheduling

    /// App came to the foreground: the user is here, so clear stale banners
    /// and bring everything up to date.
    func appBecameActive() {
        Task {
            await center.removeDelivered()
            await refreshAuthorizationStatus()
            refresh()
        }
    }

    /// Rebuilds the schedule and badge from the current library and settings.
    func refresh() {
        guard let context else { return }
        let plan: NotificationPlan?
        do {
            plan = try makePlan(context: context)
        } catch {
            log.error("Could not plan notifications: \(error)")
            return
        }

        let previous = applyChain
        applyChain = Task { [center] in
            await previous?.value
            await center.replaceScheduled(with: plan?.notifications ?? [])
            await center.setBadgeCount(plan?.badgeNow ?? 0)
        }
    }

    /// Waits for the schedule changes queued by ``refresh()`` to finish.
    func waitForPendingWork() async {
        await applyChain?.value
    }

    /// Saves can come in bursts (a session writes several things); wait for
    /// them to settle before rebuilding.
    private func refreshSoon() {
        debounce?.cancel()
        debounce = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            refresh()
        }
    }

    /// `nil` when nothing should be scheduled (not allowed, or nothing enabled).
    /// The badge is then cleared.
    private func makePlan(context: ModelContext, now: Date = .now) throws -> NotificationPlan? {
        let preferences = preferences
        guard isAuthorized, preferences.isAnythingEnabled else { return nil }
        return try NotificationPlanner.plan(
            preferences: preferences,
            items: Self.dueItems(in: context),
            practicedDays: PracticeStats.practiceDays(
                from: context.fetch(FetchDescriptor<PracticeSession>()),
                calendar: calendar,
            ),
            now: now,
            calendar: calendar,
        )
    }

    /// Passages and standalone verses with when each is next due — mirroring
    /// Home: a passage is due when any of its verses is, and brand-new
    /// material is due immediately.
    static func dueItems(in context: ModelContext) throws -> [DueItem] {
        func dueDate(_ verse: Verse) -> Date {
            verse.nextPractice ?? (verse.isNew ? .distantPast : .distantFuture)
        }

        let passages = try context.fetch(FetchDescriptor<Passage>()).compactMap { passage -> DueItem? in
            guard let earliest = (passage.verses ?? []).map(dueDate).min() else { return nil }
            return DueItem(label: passage.reference, dueDate: earliest)
        }
        let standalone = try context.fetch(FetchDescriptor<Verse>())
            .filter(\.addedDirectly)
            .map { DueItem(label: $0.reference, dueDate: dueDate($0)) }
        return passages + standalone
    }
}

/// Handles notifications that arrive while the app is open, and taps.
final nonisolated class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    /// The user is already in the app: no banner or sound, but keep the badge.
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
    ) async -> UNNotificationPresentationOptions {
        [.badge]
    }

    /// Tapping a reminder just opens the app; Home's Up Next lists what's due.
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive _: UNNotificationResponse,
    ) async {}
}
