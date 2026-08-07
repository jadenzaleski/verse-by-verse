//
//  AddVersesToSetView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/10/26.
//

import SwiftData
import SwiftUI

/// Picker for adding already-tracked verses to a study set.
struct AddVersesToSetView: View {
    let set: StudySet

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allVerses: [Verse]

    @State private var selected: Set<PersistentIdentifier> = []

    private let log = AppLog.category("AddVersesToSetView")

    private var availableVerses: [Verse] {
        let inSet = Set((set.verses ?? []).map(\.persistentModelID))
        return allVerses
            .filter { !inSet.contains($0.persistentModelID) }
            .sorted { ($0.book, $0.chapter, $0.number) < ($1.book, $1.chapter, $1.number) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if availableVerses.isEmpty {
                    ContentUnavailableView(
                        "No Verses to Add",
                        systemImage: "text.book.closed",
                        description: Text("All your tracked verses are already in this set."),
                    )
                } else {
                    List(availableVerses) { verse in
                        Button {
                            toggle(verse.persistentModelID)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                    Text(verse.reference)
                                        .font(.app(weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text(verse.translation)
                                        .font(.app(.caption))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(
                                    systemName: selected.contains(verse.persistentModelID)
                                        ? "checkmark.circle.fill" : "circle",
                                )
                                .foregroundStyle(
                                    selected.contains(verse.persistentModelID) ? Color.appAccent
                                        : Color.secondary,
                                )
                                .font(.title2)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add Verses")
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
                        confirm()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityLabel("Add selected verses")
                    .disabled(selected.isEmpty)
                }
            }
        }
    }

    private func toggle(_ id: PersistentIdentifier) {
        if selected.contains(id) {
            selected.remove(id)
        } else {
            selected.insert(id)
        }
    }

    private func confirm() {
        let additions = availableVerses.filter { selected.contains($0.persistentModelID) }
        if set.verses == nil { set.verses = [] }
        set.verses?.append(contentsOf: additions)
        set.modifiedAt = .now
        do {
            try modelContext.save()
        } catch {
            log.error("Failed to add verses to set: \(error)")
        }
        dismiss()
    }
}

#Preview {
    if let set = PreviewData.studySets.last {
        AddVersesToSetView(set: set)
            .modelContainer(PreviewData.container)
            .environment(\.font, .app())
    }
}
