//
//  AddStudySetView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/11/26.
//

import SwiftUI

struct AddStudySetView: View {
    @Environment(StudySetStore.self) private var studySetStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedTheme: MeshTheme = .ocean
    @State private var isCreating = false

    private var nameIsValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && name.count <= 100
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Theme picker with live preview
                    Text("Appearance")
                        .font(.app(.headline))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(MeshTheme.allCases) { theme in
                                VStack(spacing: 8) {
                                    SetCard(
                                        title: name.isEmpty ? theme.displayName : name,
                                        positionSeed: 42,
                                        colorShuffleSeed: 7,
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

                    // Name field
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

                    // Description field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.app(.headline))

                        TextField("Optional", text: $description, axis: .vertical)
                            .font(.app())
                            .lineLimit(3 ... 5)
                            .padding()
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Error
                    if let error = studySetStore.lastError {
                        Text(error.localizedDescription)
                            .font(.app(.caption))
                            .foregroundStyle(.red)
                            .padding(.top, 4)
                    }
                }
                .padding()
            }
            .navigationTitle("New Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.app())
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await create() }
                    }
                    .font(.app(weight: .semibold))
                    .disabled(!nameIsValid || isCreating)
                }
            }
        }
    }

    private func create() async {
        isCreating = true
        defer { isCreating = false }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedDesc = description.trimmingCharacters(in: .whitespaces)

        do {
            try await studySetStore.createSet(
                name: trimmedName,
                description: trimmedDesc.isEmpty ? nil : trimmedDesc,
                theme: selectedTheme,
            )
            dismiss()
        } catch {
            // error is already stored in studySetStore.lastError
        }
    }
}

#Preview {
    AddStudySetView()
        .environment(\.font, .app())
        .environment(StudySetStore.shared)
}
