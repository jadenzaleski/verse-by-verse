//
//  AddSetView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/11/26.
//

import SwiftUI

struct AddSetView: View {
    var title: String
    var initialName: String
    var initialDescription: String
    var initialTheme: MeshTheme
    var positionSeed: Int
    var colorSeed: Int
    var confirmSystemImage: String
    var confirmTint: Color
    var onConfirm: (_ name: String, _ description: String?, _ theme: MeshTheme) throws -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var description: String
    @State private var selectedTheme: MeshTheme
    @State private var errorMessage: String?

    init(
        title: String,
        initialName: String = "",
        initialDescription: String = "",
        initialTheme: MeshTheme = .ocean,
        positionSeed: Int = 42,
        colorSeed: Int = 7,
        confirmSystemImage: String,
        confirmTint: Color,
        onConfirm: @escaping (_ name: String, _ description: String?, _ theme: MeshTheme) throws -> Void,
    ) {
        self.title = title
        self.initialName = initialName
        self.initialDescription = initialDescription
        self.initialTheme = initialTheme
        self.positionSeed = positionSeed
        self.colorSeed = colorSeed
        self.confirmSystemImage = confirmSystemImage
        self.confirmTint = confirmTint
        self.onConfirm = onConfirm
        _name = State(initialValue: initialName)
        _description = State(initialValue: initialDescription)
        _selectedTheme = State(initialValue: initialTheme)
    }

    private var nameIsValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && name.count <= 100
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        SetThemePickerView(
                            selectedTheme: $selectedTheme,
                            positionSeed: positionSeed,
                            colorSeed: colorSeed,
                        )
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            SetMesh(
                                colorPallette: selectedTheme.palette,
                                colorShuffleSeed: colorSeed,
                                positionSeed: positionSeed,
                            )
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                            .frame(width: 36, height: 36)

                            Text("Appearance")

                            Spacer()

                            Text(selectedTheme.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    TextField("e.g. The Gospels", text: $name)
                        .font(.app())
                        .submitLabel(.next)
                } header: {
                    Text("Name")
                } footer: {
                    if name.count > 100 {
                        Text("Name must be 100 characters or fewer")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    TextField("Optional", text: $description, axis: .vertical)
                        .font(.app())
                        .lineLimit(3 ... 5)
                } header: {
                    Text("Description")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        confirm()
                    } label: {
                        Image(systemName: confirmSystemImage)
                    }
                    .accessibilityLabel("Save set")
                    .tint(confirmTint)
                    .buttonStyle(.glassProminent)
                    .disabled(!nameIsValid)
                }
            }
        }
    }

    private func confirm() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedDesc = description.trimmingCharacters(in: .whitespaces)

        do {
            try onConfirm(trimmedName, trimmedDesc.isEmpty ? nil : trimmedDesc, selectedTheme)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview("Create") {
    AddSetView(
        title: "New Set",
        confirmSystemImage: "plus",
        confirmTint: .green,
    ) { _, _, _ in }
        .environment(\.font, .app())
}
