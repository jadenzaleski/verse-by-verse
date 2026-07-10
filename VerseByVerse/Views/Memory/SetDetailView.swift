//
//  SetDetailView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/19/26.
//

import SwiftData
import SwiftUI

struct SetDetailView: View {
    let set: StudySet

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAddPassages = false

    private let log = AppLog.category("SetDetailView")

    /// The set's passages, newest first.
    private var passages: [Passage] {
        (set.passages ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                SetMesh(colorPallette: set.meshTheme.palette,
                        colorShuffleSeed: set.meshColorSeed,
                        positionSeed: set.meshPositionSeed)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 200)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .glassEffect(in: RoundedRectangle(cornerRadius: AppRadius.lg))

                Text(set.name)
                    .font(.app(.title3, weight: .semibold))
                HStack {
                    Text(set.setDescription ?? " ")
                        .font(.app(.callout))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                if !passages.isEmpty {
                    HStack {
                        Text("Passages")
                            .font(.app(.headline, weight: .semibold))
                        Spacer()
                        Text("\(passages.count)")
                            .font(.app(.subheadline))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, AppSpacing.sm)

                    ForEach(passages) { passage in
                        NavigationLink(destination: PassageDetailView(passage: passage)) {
                            PassageCard(passage: passage, style: .compact)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                remove(passage)
                            } label: {
                                Label("Remove from Set", systemImage: "minus.circle")
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .scrollIndicators(.hidden)
        .background(SetMesh(colorPallette: set.meshTheme.palette,
                            colorShuffleSeed: set.meshColorSeed,
                            positionSeed: set.meshPositionSeed).opacity(0.5).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Set", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("Set options")
            }
            ToolbarItem {
                Button {
                    showingAddPassages = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add passages to set")
            }
        }
        .sheet(isPresented: $showingAddPassages) {
            AddPassagesToSetView(set: set)
        }
        .sheet(isPresented: $showingEditSheet) {
            StudySetFormView(
                title: "Edit Set",
                initialName: set.name,
                initialDescription: set.setDescription ?? "",
                initialTheme: set.meshTheme,
                positionSeed: set.meshPositionSeed,
                colorSeed: set.meshColorSeed,
                confirmSystemImage: "checkmark",
                confirmTint: .blue,
            ) { name, description, theme in
                set.name = name
                set.setDescription = description
                set.meshTheme = theme
                set.modifiedAt = .now
                try modelContext.save()
            }
        }
        .confirmationDialog(
            "Delete \"\(set.name)\"?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible,
        ) {
            Button("Delete", role: .destructive) {
                deleteSet()
            }
        } message: {
            Text("This set will be permanently deleted. Its passages stay in your library.")
        }
    }

    private func remove(_ passage: Passage) {
        set.passages?.removeAll { $0 === passage }
        set.modifiedAt = .now
        save()
    }

    private func deleteSet() {
        modelContext.delete(set)
        do {
            try Verse.sweepOrphans(in: modelContext)
        } catch {
            log.error("Orphan sweep failed: \(error)")
        }
        save()
        dismiss()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            log.error("Failed to save set change: \(error)")
        }
    }
}

// MARK: - Preview

#Preview("SetDetailView") {
    NavigationStack {
        if let set = PreviewData.studySets.first {
            SetDetailView(set: set)
        }
    }
    .modelContainer(PreviewData.container)
    .environment(\.font, .app())
    .environment(BibleStore.shared)
}
