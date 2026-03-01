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
                        Label("Name", image: "lucide.id.card.lanyard")
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
                        Label("Email", image: "lucide.mail")
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
                        Label("Password", image: "lucide.lock")
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
                Label {
                    Text(AppFunctions.versionString() ?? "")
                } icon: {
                    Image("lucide.rocket")
                }
                Label {
                    Text(user?.id ?? "Unknown id")
                        .lineLimit(1)
                        .textSelection(.enabled)
                } icon: {
                    Image("lucide.hash")
                }

            } header: {
                Text("ABOUT")
                    .font(Font.app(.footnote, weight: .semibold))
            }

            Section {
                NavigationLink {
                    DeveloperView()
                } label: {
                    Label("Developer", image: "lucide.hammer")
                }
            }

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
                PasswordEditorView { current, new in
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

private struct NameEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserStore.self) private var userStore

    @State var firstName: String
    @State var lastName: String

    var onSave: (_ first: String, _ last: String) async throws -> Void

    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("First name", text: $firstName)
                        .textContentType(.givenName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)

                    TextField("Last name", text: $lastName)
                        .textContentType(.familyName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                } footer: {
                    if case .loading = userStore.state {
                        HStack {
                            Spacer()
                            ProgressView()
                                .font(.app(.footnote))
                            Spacer()
                        }
                    }

                    if let errorMessage = userStore.lastError?.localizedDescription {
                        Text(errorMessage)
                            .font(.app(.footnote))
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            do {
                                try await onSave(firstName, lastName)
                                dismiss()
                            } catch {
                                // Error is handled by UserStore
                            }
                        }
                    } label: {
                        if case .loading = userStore.state {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accent)
                    .disabled(!isValid || userStore.state == .loading)
                }
            }
        }
    }
}

private struct EmailEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserStore.self) private var userStore

    @State var email: String

    var onSave: (_ email: String) async throws -> Void

    private var isValid: Bool {
        // Basic validation; replace with your own
        email.contains("@") && email.contains(".")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } footer: {
                    if case .loading = userStore.state {
                        HStack {
                            Spacer()
                            ProgressView()
                                .font(.app(.footnote))
                            Spacer()
                        }
                    }

                    if let errorMessage = userStore.lastError?.errorDescription {
                        Text(errorMessage)
                            .font(.app(.footnote))
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            do {
                                try await onSave(email)
                                dismiss()
                            } catch {
                                // Error handled by UserStore
                            }
                        }
                    } label: {
                        if case .loading = userStore.state {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accent)
                    .disabled(!isValid || userStore.state == .loading)
                }
            }
        }
    }
}

private struct PasswordEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserStore.self) private var userStore

    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""

    var onSave: (_ current: String, _ new: String) async throws -> Void

    private var isValid: Bool {
        !currentPassword.isEmpty &&
            newPassword.count >= 8 &&
            newPassword == confirmPassword
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Current password", text: $currentPassword)
                        .textContentType(.password)
                    SecureField("New password", text: $newPassword)
                        .textContentType(.newPassword)
                    SecureField("Confirm new password", text: $confirmPassword)
                        .textContentType(.newPassword)
                } footer: {
                    if case .loading = userStore.state {
                        HStack {
                            Spacer()
                            ProgressView()
                                .font(.app(.footnote))
                            Spacer()
                        }
                    }

                    if let errorMessage = userStore.lastError?.localizedDescription {
                        Text(errorMessage)
                            .font(.app(.footnote))
                            .foregroundStyle(.red)
                    }

                    if !confirmPassword.isEmpty, newPassword != confirmPassword {
                        Text("Passwords do not match")
                            .font(.app(.footnote))
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            do {
                                try await onSave(currentPassword, newPassword)
                                dismiss()
                            } catch {
                                // Error handled by UserStore and shown in footer
                            }
                        }
                    } label: {
                        if case .loading = userStore.state {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accent)
                    .disabled(!isValid || userStore.state == .loading)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.font, .app())
}
