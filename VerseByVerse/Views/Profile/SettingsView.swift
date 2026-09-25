//
//  SettingsView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/27/25.
//

import SwiftUI

struct SettingsView: View {
    private let log = AppLog.category("SettingsView")

    @Environment(\.openURL) private var openURL
    @AppStorage(.displayName) private var displayName = ""

    @State private var showConfirmClearCache = false
    @State private var showMailUnavailable = false
    /// Exported log file backing the Share Diagnostics row. Prepared off the
    /// main actor in `.task` so opening Settings never blocks on disk I/O.
    @State private var diagnosticsURL: URL?

    var body: some View {
        List {
            profileSection
            generalSection
            supportSection
            aboutSection

            #if DEBUG || BETA
                developerSection
            #endif // DEBUG || BETA
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await prepareDiagnostics()
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
            Button("Clear Cache") {
                showConfirmClearCache = true
            }
            .confirmationDialog(
                "Clear Cache",
                isPresented: $showConfirmClearCache,
            ) {
                Button("Clear", role: .destructive) {
                    Cache.shared.removeAll()
                }
            } message: {
                Text("Are you sure you want to clear the cache?")
            }
            .accessibilityLabel("Clear Cache")
        } header: {
            Text("GENERAL")
                .font(Font.app(.footnote, weight: .semibold))
        } footer: {
            Text("Clears downloaded Bible text. Your passages and practice history are not affected.")
                .font(.app(.caption2))
        }
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

            if let diagnosticsURL {
                ShareLink(item: diagnosticsURL) {
                    Label("Share Diagnostics", systemImage: "doc.text")
                }
                .accessibilityHint("Shares a log file you can attach to a support email")
            }
        } header: {
            Text("SUPPORT")
                .font(Font.app(.footnote, weight: .semibold))
        } footer: {
            Text("""
            Contact Support opens an email with your app version and iOS version filled in. \
            Diagnostics is a log of what the app did. This contains no personal information, and nothing is sent anywhere until you share it.
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

    /// Writes the exportable log file off the main actor. Failure just leaves
    /// the Share Diagnostics row hidden — Contact Support still works.
    private func prepareDiagnostics() async {
        diagnosticsURL = await Task.detached(priority: .utility) {
            LoggingService.shared.exportLogs()
        }.value
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(\.font, .app())
    }
}
