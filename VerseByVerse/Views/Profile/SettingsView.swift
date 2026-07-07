//
//  SettingsView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/27/25.
//

import SwiftUI

struct SettingsView: View {
    private let log = AppLog.category("SettingsView")
    @AppStorage(.displayName) private var displayName = ""

    var body: some View {
        List {
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
            } footer: {
                Text("Only used for the greeting on your Home tab. Stays on this device.")
                    .font(.app(.caption2))
            }

            Section {
                Button("Clear Cache") {
                    Cache.shared.removeAll()
                }
            } header: {
                Text("GENERAL")
                    .font(Font.app(.footnote, weight: .semibold))
            } footer: {
                Text("Clears downloaded Bible text. Your passages and practice history are not affected.")
                    .font(.app(.caption2))
            }

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
            } header: {
                Text("ABOUT")
                    .font(Font.app(.footnote, weight: .semibold))
            }

            #if DEBUG || BETA
                Section {
                    NavigationLink {
                        DeveloperView()
                    } label: {
                        Label("Developer", systemImage: "hammer.fill")
                    }
                }
            #endif // DEBUG || BETA
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(\.font, .app())
    }
}
