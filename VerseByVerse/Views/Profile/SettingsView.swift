//
//  SettingsView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/27/25.
//

import SwiftUI

struct SettingsView: View {
    var id: String?
    private let log = AppLog.category("SettingsView")

    @State private var activeSheet: Sheet?
    @State private var user: UserResponse?
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""

    private enum Sheet: String, Identifiable {
        case name, email, password
        var id: String {
            rawValue
        }
    }

    var body: some View {
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
                    Text(id ?? "Unknown id")
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
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet) { type in
            switch type {
            case .name:
                NameEditorView(
                    firstName: user?.firstName ?? "",
                    lastName: user?.lastName ?? "",
                ) { newFirst, newLast in
                    Task {
                        do {
                            _ = try await APIService.shared.patchUser(firstName: newFirst, lastName: newLast)
                            Cache.shared.remove("getUser")
                            firstName = newFirst
                            lastName = newLast
                        } catch {
                            log.error("patchUser error: \(error.localizedDescription)")
                        }
                    }
                }

            case .email:
                EmailEditorView(
                    email: user?.email ?? "",
                ) { newEmail in
                    do {
                        _ = try await APIService.shared.patchUser(email: newEmail)
                        Cache.shared.remove("getUser")
                        await MainActor.run { email = newEmail }
                    } catch {
                        log.error("patchUser error: \(error.localizedDescription)")
                        throw error
                    }
                }

            case .password:
                PasswordEditorView { _, _ in
                    // TODO: Call your API to update password
                    // e.g., try await APIService.shared.updatePassword(current: current, new: new)
                }
            }
        }
        .task {
            do {
                user = try await APIService.shared.getUser()
            } catch {
                log.error("Failed to load user: \(String(describing: error))")
            }
        }
    }
}

private struct NameEditorView: View {
    @Environment(\.dismiss) private var dismiss

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
                            try? await onSave(firstName, lastName)
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accent)
                    .disabled(!isValid)
                }
            }
        }
    }
}

private struct EmailEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State var email: String
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?

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
                    if isSaving {
                        HStack {
                            Spacer()
                            ProgressView()
                                .font(.app(.footnote))
                            Spacer()
                        }
                    }

                    if let errorMessage {
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
                            guard !isSaving else { return }
                            isSaving = true
                            errorMessage = nil
                            do {
                                try await onSave(email)
                                dismiss()
                            } catch {
                                // Map specific backend error code to a user-friendly message
                                let message = error.localizedDescription
                                if message.contains("UPDATE_USER_EMAIL_ALREADY_EXISTS") {
                                    errorMessage = "That email is already in use. Please try a different email."
                                } else {
                                    errorMessage = "We couldn't update your email. Please try again."
                                }
                            }
                            isSaving = false
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accent)
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }
}

private struct PasswordEditorView: View {
    @Environment(\.dismiss) private var dismiss

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
                }

                if !confirmPassword.isEmpty, newPassword != confirmPassword {
                    Text("Passwords do not match")
                        .font(.app(.footnote))
                        .foregroundStyle(.red)
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
                            try? await onSave(currentPassword, newPassword)
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accent)
                    .disabled(!isValid)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.font, .app())
}
