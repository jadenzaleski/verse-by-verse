//
//  AddPassagesToSetView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/20/26.
//

import SwiftData
import SwiftUI

struct AddPassagesToSetView: View {
    let set: StudySet

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Passage.createdAt, order: .reverse) private var allPassages: [Passage]

    @State private var selected: Set<PersistentIdentifier> = []

    private let log = AppLog.category("AddPassagesToSetView")

    private var availablePassages: [Passage] {
        let inSet = Set((set.passages ?? []).map(\.persistentModelID))
        return allPassages.filter { !inSet.contains($0.persistentModelID) }
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
                            toggle(passage.persistentModelID)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                    Text(passage.reference)
                                        .font(.app(weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text(passage.translation)
                                        .font(.app(.caption))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(
                                    systemName: selected.contains(passage.persistentModelID)
                                        ? "checkmark.circle.fill" : "circle",
                                )
                                .foregroundStyle(
                                    selected.contains(passage.persistentModelID) ? Color.appAccent
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
            .navigationTitle("Add Passages")
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
                    .accessibilityLabel("Add selected passages")
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
        let additions = availablePassages.filter { selected.contains($0.persistentModelID) }
        if set.passages == nil { set.passages = [] }
        set.passages?.append(contentsOf: additions)
        set.modifiedAt = .now
        do {
            try modelContext.save()
        } catch {
            log.error("Failed to add passages to set: \(error)")
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview("AddPassagesToSetView") {
    if let set = PreviewData.studySets.last {
        AddPassagesToSetView(set: set)
            .modelContainer(PreviewData.container)
            .environment(\.font, .app())
    }
}
