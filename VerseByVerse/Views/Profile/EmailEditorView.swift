//
//  EmailEditorView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/4/26.
//

import SwiftUI

struct EmailEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserStore.self) private var userStore

    @State private var email: String

    var onSave: (_ email: String) async throws -> Void

    init(email: String, onSave: @escaping (_ email: String) async throws -> Void) {
        _email = State(initialValue: email)
        self.onSave = onSave
    }

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
