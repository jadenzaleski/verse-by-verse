//
//  NameEditorView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/4/26.
//

import SwiftUI

struct NameEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserStore.self) private var userStore

    @State private var firstName: String
    @State private var lastName: String

    var onSave: (_ first: String, _ last: String) async throws -> Void

    init(
        firstName: String,
        lastName: String,
        onSave: @escaping (_ first: String, _ last: String) async throws -> Void,
    ) {
        _firstName = State(initialValue: firstName)
        _lastName = State(initialValue: lastName)
        self.onSave = onSave
    }

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
