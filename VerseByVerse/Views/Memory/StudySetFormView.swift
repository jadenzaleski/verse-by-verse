//
//  StudySetFormView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/11/26.
//

import SwiftUI

struct StudySetFormView: View {
    var title: String
    var initialName: String
    var initialDescription: String
    var initialTheme: MeshTheme
    var positionSeed: Int
    var colorSeed: Int
    var confirmSystemImage: String
    var confirmTint: Color
    var onConfirm: (_ name: String, _ description: String?, _ theme: MeshTheme) async throws -> Void

    @Environment(StudySetStore.self) private var studySetStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var description: String
    @State private var selectedTheme: MeshTheme
    @State private var isWorking = false

    init(
        title: String,
        initialName: String = "",
        initialDescription: String = "",
        initialTheme: MeshTheme = .ocean,
        positionSeed: Int = 42,
        colorSeed: Int = 7,
        confirmSystemImage: String,
        confirmTint: Color,
        onConfirm: @escaping (_ name: String, _ description: String?, _ theme: MeshTheme) async throws -> Void,
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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Appearance")
                        .font(.app(.headline))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(MeshTheme.allCases) { theme in
                                VStack(spacing: 8) {
                                    SetCard(
                                        title: name.isEmpty ? theme.displayName : name,
                                        positionSeed: positionSeed,
                                        colorShuffleSeed: colorSeed,
                                        colorPallette: theme.palette,
                                    )
                                    .frame(width: 120)
                                    .overlay(alignment: .top) {
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                selectedTheme == theme ? Color.accentColor : Color.clear,
                                                lineWidth: 3,
                                            )
                                            .frame(width: 120, height: 120)
                                    }
                                    .onTapGesture {
                                        withAnimation(.snappy) { selectedTheme = theme }
                                    }

                                    Image(systemName: selectedTheme == theme ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedTheme == theme ? Color.accentColor : .secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.app(.headline))

                        TextField("e.g. The Gospels", text: $name)
                            .font(.app())
                            .padding()
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                            .submitLabel(.next)

                        if name.count > 100 {
                            Text("Name must be 100 characters or fewer")
                                .font(.app(.caption))
                                .foregroundStyle(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.app(.headline))

                        TextField("Optional", text: $description, axis: .vertical)
                            .font(.app())
                            .lineLimit(3 ... 5)
                            .padding()
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                    }

                    if let error = studySetStore.lastError {
                        Text(error.localizedDescription)
                            .font(.app(.caption))
                            .foregroundStyle(.red)
                            .padding(.top, 4)
                    }
                }
                .padding()
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
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await confirm() }
                    } label: {
                        Image(systemName: confirmSystemImage)
                    }
                    .tint(confirmTint)
                    .buttonStyle(.glassProminent)
                    .disabled(!nameIsValid || isWorking)
                }
            }
        }
    }

    private func confirm() async {
        isWorking = true
        defer { isWorking = false }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedDesc = description.trimmingCharacters(in: .whitespaces)

        do {
            try await onConfirm(trimmedName, trimmedDesc.isEmpty ? nil : trimmedDesc, selectedTheme)
            dismiss()
        } catch {
            // error stored in studySetStore.lastError
        }
    }
}

// MARK: - Preview

#Preview("Create") {
    StudySetFormView(
        title: "New Set",
        confirmSystemImage: "plus",
        confirmTint: .green,
    ) { _, _, _ in }
        .environment(\.font, .app())
        .environment(StudySetStore.shared)
}
