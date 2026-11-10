//
//  SettingsView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/27/25.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    private let log = AppLog.category("SettingsView")

    @Environment(\.openURL) private var openURL
    @Environment(BibleStore.self) private var bibleStore
    @Environment(\.modelContext) private var modelContext
    @AppStorage(.displayName) private var displayName = ""
    @AppStorage(.dailyReminderEnabled) private var dailyReminderEnabled = false
    @AppStorage(.dailyReminderMinutes) private var dailyReminderMinutes = NotificationPreferences
        .defaultDailyReminderMinutes
    @AppStorage(.streakReminderEnabled) private var streakReminderEnabled = false
    @AppStorage(.dueBadgeEnabled) private var dueBadgeEnabled = false

    private let scheduler = NotificationScheduler.shared

    @State private var showConfirmClearCache = false
    @State private var showMailUnavailable = false
    @State private var isSharingDiagnostics = false
    @State private var showDiagnosticsFailed = false
    /// True from tapping Export My Data until the share sheet is on screen;
    /// drives the spinner on the row.
    @State private var isExporting = false
    @State private var showExportFailed = false
    @State private var showNotificationsDenied = false

    var body: some View {
        List {
            profileSection
            generalSection
            notificationSection
            supportSection
            aboutSection

            #if DEBUG || BETA
                developerSection
            #endif // DEBUG || BETA
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await scheduler.refreshAuthorizationStatus()
        }
        .onChange(of: dailyReminderMinutes) {
            scheduler.refresh()
        }
        .alert("Notifications Are Off", isPresented: $showNotificationsDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                    openURL(url)
                }
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("Turn on notifications for Verse by Verse in the Settings app to get reminders.")
        }
        .alert("Couldn't Share Diagnostics", isPresented: $showDiagnosticsFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The log file couldn't be prepared. Please try again.")
        }
        .alert("Export Failed", isPresented: $showExportFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your data couldn't be prepared. Please try again.")
        }
        .alert("Mail Not Available", isPresented: $showMailUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("No mail account is set up on this device. You can reach us at \(AppLinks.supportEmail).")
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section {
            HStack {
                Label("Name", systemImage: "person.text.rectangle")
                Spacer()
                TextField("What should we call you?", text: $displayName)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
                    .textInputAutocapitalization(.words)
            }
        } header: {
            Text("PROFILE")
                .font(Font.app(.footnote, weight: .semibold))
        }
    }

    // MARK: - General

    private var generalSection: some View {
        Section {
            shareRow(
                "Export My Data",
                systemImage: "square.and.arrow.up",
                isBusy: isExporting,
                hint: "Saves your passages, sets and practice history as a JSON file",
                action: exportData,
            )

            Button {
                showConfirmClearCache = true
            } label: {
                Label("Clear Cache", systemImage: "shippingbox")
            }
            .confirmationDialog(
                "Clear Cache",
                isPresented: $showConfirmClearCache,
            ) {
                Button("Clear", role: .destructive) {
                    Task { await bibleStore.clearCache() }
                }
            } message: {
                Text("Are you sure you want to clear the cache?")
            }
            .accessibilityLabel("Clear Cache")
        } header: {
            Text("GENERAL")
                .font(Font.app(.footnote, weight: .semibold))
        } footer: {
            Text("""
            Clear Cache removes downloaded Bible text.
            Your passages and practice history are not affected.
            """)
            .font(.app(.caption2))
        }
    }

    // MARK: - Notification

    private var notificationSection: some View {
        Section {
            notificationToggle(
                "Daily Reminder",
                systemImage: "bell",
                isOn: $dailyReminderEnabled,
                hint: "Reminds you once a day when reviews are due",
            )
            if dailyReminderEnabled {
                HStack {
                    Label("Time", systemImage: "clock")
                    Spacer()
                    DatePicker("", selection: reminderTime, displayedComponents: .hourAndMinute)
                }
            }

            notificationToggle(
                "Streak Reminder",
                systemImage: "flame",
                isOn: $streakReminderEnabled,
                hint: "Reminds you at 8 PM when your streak is about to end",
            )

            notificationToggle(
                "Due Count Badge",
                systemImage: "app.badge",
                isOn: $dueBadgeEnabled,
                hint: "Shows how many reviews are due on the app icon",
            )
        } header: {
            Text("NOTIFICATIONS")
                .font(Font.app(.footnote, weight: .semibold))
        } footer: {
            Text("""
            Daily Reminder only goes out on days when something is due.
            """)
            .font(.app(.caption2))
        }
    }

    /// The reminder time as a `Date` for the picker; stored as minutes after midnight.
    private var reminderTime: Binding<Date> {
        Binding {
            let calendar = Calendar.current
            return calendar.date(
                bySettingHour: dailyReminderMinutes / 60,
                minute: dailyReminderMinutes % 60,
                second: 0,
                of: .now,
            ) ?? .now
        } set: { newValue in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            dailyReminderMinutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        }
    }

    /// A switch that asks for notification permission the first time it is
    /// turned on, and turns itself back off if the answer is no.
    private func notificationToggle(
        _ title: String,
        systemImage: String,
        isOn: Binding<Bool>,
        hint: String,
    ) -> some View {
        Toggle(isOn: Binding(
            get: { isOn.wrappedValue },
            set: { newValue in
                isOn.wrappedValue = newValue
                Task { await notificationSettingChanged(isOn, enabled: newValue) }
            },
        )) {
            Label(title, systemImage: systemImage)
        }
        .accessibilityHint(hint)
    }

    private func notificationSettingChanged(_ setting: Binding<Bool>, enabled: Bool) async {
        if enabled, await !scheduler.requestAuthorizationIfNeeded() {
            setting.wrappedValue = false
            showNotificationsDenied = true
        }
        scheduler.refresh()
    }

    // MARK: - Support

    private var supportSection: some View {
        Section {
            Button {
                contactSupport()
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }
            .accessibilityHint("Opens a new email to the developer")

            shareRow(
                "Share Diagnostics",
                systemImage: "doc.text",
                isBusy: isSharingDiagnostics,
                hint: "Shares a log file you can attach to a support email",
                action: shareDiagnostics,
            )
        } header: {
            Text("SUPPORT")
                .font(Font.app(.footnote, weight: .semibold))
        } footer: {
            Text("""
            Contact Support opens an email with your app version and iOS version filled in. \
            Diagnostics is a log of what the app did. \
            This contains no personal information, \
            and nothing is sent anywhere until you share it.
            """)
            .font(.app(.caption2))
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            Label {
                HStack(spacing: AppSpacing.sm) {
                    Text(AppFunctions.versionString() ?? "")
                    if let badge = AppFunctions.channel.badge {
                        Text(badge)
                            .font(.app(.caption2, weight: .semibold))
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(Capsule().fill(AppFunctions.channel.badgeColor.opacity(0.15)))
                            .foregroundStyle(AppFunctions.channel.badgeColor)
                    }
                    if AppAttestClient.shared.isAttested {
                        Spacer()
                        Label("Secure connection", systemImage: "lock")
                            .labelStyle(.iconOnly)
                            .opacity(0.5)
                    }
                }
            } icon: {
                Image(systemName: "app.badge")
            }

            Link(destination: AppLinks.website) {
                Label("Website", systemImage: "globe")
            }
            .accessibilityHint("Opens versebyverse.jadenzaleski.com in your browser")

            Link(destination: AppLinks.privacyPolicy) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            .accessibilityHint("Opens the privacy policy in your browser")

            Link(destination: AppLinks.github) {
                Label {
                    Text("GitHub")
                } icon: {
                    Image("github")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
            }
            .accessibilityHint("Opens the GitHub repository in your browser")
        } header: {
            Text("ABOUT")
                .font(Font.app(.footnote, weight: .semibold))
        } footer: {
            Text("Verse by Verse keeps your passages and practice history on this device.")
                .font(.app(.caption2))
        }
    }

    // MARK: - Developer

    #if DEBUG || BETA
        private var developerSection: some View {
            Section {
                NavigationLink {
                    DeveloperView()
                } label: {
                    Label("Developer", systemImage: "hammer.fill")
                }
            }
        }
    #endif // DEBUG || BETA

    // MARK: - Actions

    /// Opens a pre-filled support email, falling back to an alert that shows
    /// the address when the device has no mail client to handle `mailto:`.
    private func contactSupport() {
        guard let url = AppLinks.supportMailto() else {
            log.error("Could not build support mailto URL")
            showMailUnavailable = true
            return
        }
        openURL(url) { accepted in
            if !accepted {
                log.info("No handler for mailto: — showing address instead")
                showMailUnavailable = true
            }
        }
    }

    /// Snapshots the library on the main actor (the models live there), writes
    /// the JSON file off it, then presents the share sheet. The spinner shows
    /// for the whole stretch, including the share sheet's own start-up.
    private func exportData() async {
        isExporting = true
        log.info("Export: started")
        // Let the spinner render before any heavy work or presentation.
        try? await Task.sleep(for: .milliseconds(50))
        do {
            let export = try DataExport.make(from: modelContext)
            let url = try await Task.detached(priority: .userInitiated) {
                try export.writeTemporaryFile()
            }.value
            log.info("Export: file ready, presenting share sheet")
            ShareSheet.present(url) {
                log.info("Export: share sheet presented")
                isExporting = false
            }
        } catch {
            log.error("Could not prepare the data export: \(error)")
            isExporting = false
            showExportFailed = true
        }
    }

    /// Writes the log file off the main actor, then presents the share sheet.
    private func shareDiagnostics() async {
        isSharingDiagnostics = true
        // Let the spinner render before any heavy work or presentation.
        try? await Task.sleep(for: .milliseconds(50))
        let url = await Task.detached(priority: .userInitiated) {
            LoggingService.shared.exportLogs()
        }.value
        guard let url else {
            log.error("Could not write the diagnostics file")
            isSharingDiagnostics = false
            showDiagnosticsFailed = true
            return
        }
        ShareSheet.present(url) { isSharingDiagnostics = false }
    }

    /// A row that prepares something, then opens the share sheet. The spinner
    /// on the right shows from the tap until the sheet is on screen, because
    /// the system share sheet can take a couple of seconds to start (longer
    /// the first time after a launch).
    private func shareRow(
        _ title: String,
        systemImage: String,
        isBusy: Bool,
        hint: String,
        action: @escaping () async -> Void,
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                if isBusy {
                    ProgressView()
                        .accessibilityLabel("Preparing")
                }
            }
        }
        .disabled(isBusy)
        .accessibilityHint(hint)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(BibleStore.shared)
            .environment(\.font, .app())
    }
    .modelContainer(PreviewData.container)
}
