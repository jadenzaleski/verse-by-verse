//
//  PasswordEditorView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/4/26.
//

import SwiftUI

struct PasswordEditorView: View {
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
