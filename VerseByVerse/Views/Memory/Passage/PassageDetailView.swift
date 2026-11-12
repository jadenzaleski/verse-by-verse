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
    @State private var isStartButtonVisible = true

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
                    totalReps: PracticeStats.completedCount(passageSessions),
                    retentionScore: retentionScore,
                    lastResult: passage.lastResult,
                    nextPracticeDate: passage.nextPractice,
                    isNew: passage.isNew,
                )
                PracticeStartButton(isVisible: $isStartButtonVisible) { showPractice = true }
                SelectionTextCard(
                    title: "Passage",
                    translation: passage.translation,
                    key: passage.selectionKey,
                    verses: passage.orderedVerses,
                )
                historyCard
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
            PracticeToolbar(
                deleteTitle: "Delete Passage",
                showsPractice: !isStartButtonVisible,
                onPractice: { showPractice = true },
                onDelete: { showDeleteConfirmation = true },
            )
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
            Text(Passage.deleteConfirmationMessage)
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
        do {
            try passage.delete(alsoDeleteVerses: alsoDeleteVerses, in: modelContext)
        } catch {
            log.error("Failed to delete passage: \(error)")
        }
        dismiss()
    }
}

#Preview("PassageDetailView") {
    NavigationStack {
        PassageDetailView(passage: PreviewData.samplePassage)
    }
    .modelContainer(PreviewData.container)
    .environment(PreviewData.bibleStore)
    .environment(\.font, .app())
}
