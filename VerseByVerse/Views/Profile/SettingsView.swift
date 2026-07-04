//
//  SettingsView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/27/25.
//

import SwiftUI

struct SettingsView: View {
    private let log = AppLog.category("SettingsView")
    @Environment(UserStore.self) private var userStore

    @State private var activeSheet: Sheet?
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var showSignOutConfirm = false

    private enum Sheet: String, Identifiable {
        case name, email, password
        var id: String {
            rawValue
        }
    }

    var body: some View {
        let user = userStore.currentUser
        let displayFirstName = (firstName.isEmpty ? (user?.firstName ?? "Unknown") : firstName)
        let displayLastName = (lastName.isEmpty ? (user?.lastName ?? "User") : lastName)
        let displayEmail = (email.isEmpty ? (user?.email ?? "Unknown@unknown.com") : email)

        List {
            Section {
                Button {
                    activeSheet = .name
                } label: {
                    HStack {
                        Label("Name", systemImage: "person.text.rectangle")
                        Spacer()
                        Text(displayFirstName + " " + displayLastName)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.app(.footnote))
                            .foregroundStyle(.tertiary)
                    }
                }

                Button {
                    activeSheet = .email
                } label: {
                    HStack {
                        Label("Email", systemImage: "envelope.fill")
                        Spacer()
                        Text(verbatim: displayEmail)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.app(.footnote))
                            .foregroundStyle(.tertiary)
                    }
                }

                Button {
                    activeSheet = .password
                } label: {
                    HStack {
                        Label("Password", systemImage: "lock.fill")
                        Spacer()
                        Text("••••••••")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.app(.footnote))
                            .foregroundStyle(.tertiary)
                    }
                }
            } header: {
                Text("PROFILE")
                    .font(Font.app(.footnote, weight: .semibold))
            }
            .buttonStyle(.plain)

            Section {} header: {
                Text("APPEARANCE")
                    .font(Font.app(.footnote, weight: .semibold))
            }

            Section {
                Button("Clear Cache") {
                    Cache.shared.removeAll()
                }
            } header: {
                Text("GENERAL")
                    .font(Font.app(.footnote, weight: .semibold))
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
                Label {
                    Text(user?.id ?? "Unknown id")
                        .lineLimit(1)
                        .textSelection(.enabled)
                } icon: {
                    Image(systemName: "number")
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

            Section {
                Button(role: .destructive) {
                    showSignOutConfirm = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet) { type in
            switch type {
            case .name:
                NameEditorView(
                    firstName: userStore.currentUser?.firstName ?? "",
                    lastName: userStore.currentUser?.lastName ?? "",
                ) { newFirst, newLast in
                    try await userStore.patchUser(firstName: newFirst, lastName: newLast)
                    firstName = newFirst
                    lastName = newLast
                }

            case .email:
                EmailEditorView(
                    email: userStore.currentUser?.email ?? "",
                ) { newEmail in
                    try await userStore.patchUser(email: newEmail)
                    await MainActor.run { email = newEmail }
                }

            case .password:
                PasswordEditorView { _, new in
                    try await userStore.patchUser(password: new)
                }
            }
        }
        .task {
            await userStore.loadUser()
        }
        .alert("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                userStore.logout()
                try? KeychainManager.clearAll()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Error", isPresented: Binding(
            get: { userStore.lastError != nil && activeSheet == nil },
            set: { _ in userStore.clearError() },
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = userStore.lastError {
                Text(error.localizedDescription)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(UserStore.shared)
        .environment(\.font, .app())
}
