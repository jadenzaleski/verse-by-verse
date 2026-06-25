//
//  AddPassagesToSetView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/20/26.
//

import SwiftUI

struct AddPassagesToSetView: View {
    let setId: Int

    @Environment(PassageStore.self) private var passageStore
    @Environment(StudySetStore.self) private var studySetStore
    @Environment(\.dismiss) private var dismiss

    @State private var selected: Set<Int> = []
    @State private var isConfirming = false
    @State private var confirmError: Error?

    private var passageIdsInSet: Set<Int> {
        Set(studySetStore.setPassageIds[setId] ?? [])
    }

    private var availablePassages: [UserPassage] {
        passageStore.userPassages.filter { !passageIdsInSet.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if availablePassages.isEmpty {
                    ContentUnavailableView(
                        "No Passages to Add",
                        systemImage: "text.book.closed",
                        description: Text("All your passages are already in this set."),
                    )
                } else {
                    List(availablePassages) { passage in
                        Button {
                            toggle(passage.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(passage.reference)
                                        .font(.app(weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text(passage.translation)
                                        .font(.app(.caption))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: selected.contains(passage.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected.contains(passage.id) ? Color.accentColor : Color.secondary)
                                    .font(.title2)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add Passages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isConfirming {
                        ProgressView()
                    } else {
                        Button {
                            Task { await confirm() }
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .disabled(selected.isEmpty)
                    }
                }
            }
        }
    }

    private func toggle(_ id: Int) {
        if selected.contains(id) {
            selected.remove(id)
        } else {
            selected.insert(id)
        }
    }

    private func confirm() async {
        isConfirming = true
        for passageId in selected {
            do {
                try await studySetStore.addPassage(toSet: setId, passageId: passageId)
            } catch {
                confirmError = error
            }
        }
        isConfirming = false
        dismiss()
    }
}

// MARK: - Preview

#Preview("AddPassagesToSetView") {
    let store = PassageStore.shared

    let allPassages: [UserPassage] = [
        UserPassage(
            id: 6, userId: "preview", book: "John",
            startChapter: 3, endChapter: 3, startVerse: 16, endVerse: 16,
            translation: "ESV",
            lastPracticed: nil, nextPractice: nil,
            stability: 1.0, difficulty: 5.0, state: 0, reps: 0,
            lapses: 0, scheduledDays: 0, elapsedDays: 0,
        ),
        UserPassage(
            id: 7, userId: "preview", book: "Psalm",
            startChapter: 23, endChapter: 23, startVerse: 1, endVerse: 6,
            translation: "ESV",
            lastPracticed: .now.addingTimeInterval(-86400),
            nextPractice: .now,
            stability: 2.0, difficulty: 5.5, state: 2, reps: 2,
            lapses: 0, scheduledDays: 1, elapsedDays: 1,
        ),
        UserPassage(
            id: 8, userId: "preview", book: "Romans",
            startChapter: 8, endChapter: 8, startVerse: 28, endVerse: 28,
            translation: "ESV",
            lastPracticed: .now.addingTimeInterval(-86400 * 3),
            nextPractice: .now.addingTimeInterval(86400 * 2),
            stability: 3.0, difficulty: 4.8, state: 2, reps: 4,
            lapses: 0, scheduledDays: 5, elapsedDays: 3,
        ),
    ]

    #if DEBUG
        store.setUserPassagesForPreview(allPassages)
    #endif

    return AddPassagesToSetView(setId: 1)
        .environment(store)
        .environment(StudySetStore.shared)
        .environment(\.font, .app())
}
