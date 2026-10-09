//
//  PassageDetailView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/4/26.
//

import SwiftData
import SwiftUI

struct PassageDetailView: View {
    let passage: Passage

    @Environment(BibleStore.self) private var bibleStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showPractice = false
    @State private var showDeleteConfirmation = false

    private let log = AppLog.category("PassageDetailView")
    private let scheduler = FSRSScheduler()

    private var passageSessions: [PracticeSession] {
        passage.sessions ?? []
    }

    /// Average probability of recall across the passage's verses, straight
    /// from the FSRS engine — the same curve that schedules reviews.
    private var retentionScore: Double {
        passage.memoryScore(using: scheduler) ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                MemoryScoreCard(
                    lastPracticed: passage.lastPracticed,
                    totalReps: passage.totalReps,
                    retentionScore: retentionScore,
                )
                PracticeCard(showPractice: $showPractice, nextPracticeDate: passage.nextPractice, isNew: passage.isNew)
                historyCard
                SelectionTextCard(title: "Passage", translation: passage.translation, key: passage.selectionKey)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxl)
        }
        .fullScreenCover(isPresented: $showPractice) {
            SessionView(passage: passage)
        }
        .navigationTitle(passage.reference)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .confirmationDialog(
                    "Delete \(passage.reference)?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible,
                ) {
                    Button("Delete Passage", role: .destructive) {
                        deletePassage(alsoDeleteVerses: false)
                    }
                    Button("Delete Passage & Verses", role: .destructive) {
                        deletePassage(alsoDeleteVerses: true)
                    }
                } message: {
                    Text("Delete Passage keeps its verses; Delete Passage & Verses also removes the verses. This can't be undone.")
                }
                .accessibilityLabel("Delete Passage")
            }
        }
    }

    // MARK: - Cards

    @ViewBuilder
    private var historyCard: some View {
        if passageSessions.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("History")
                    .font(.app(.title2))
                Text("No practice history yet.")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("History")
                    .font(.app(.title2))
                    .padding([.horizontal, .top])
                PassageMemoryScoreChart(sessions: passageSessions)
                    .padding()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        }
    }

    private func deletePassage(alsoDeleteVerses: Bool) {
        if !alsoDeleteVerses {
            for verse in passage.verses ?? [] {
                verse.addedDirectly = true
            }
        }
        modelContext.delete(passage)
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
            log.error("Failed to save passage change: \(error)")
        }
    }
}

#Preview("PassageDetailView") {
    NavigationStack {
        PassageDetailView(passage: PreviewData.samplePassage)
    }
    .modelContainer(PreviewData.container)
    .environment(BibleStore.shared)
    .environment(\.font, .app())
}
