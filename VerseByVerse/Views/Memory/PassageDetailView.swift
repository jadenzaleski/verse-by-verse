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

    @State private var showPractice = false

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
                    retentionScore: retentionScore)
                PracticeCard(showPractice: $showPractice, nextPracticeDate: passage.nextPractice, isNew: passage.isNew)
                historyCard
                LongTextCard(
                    title: "Passage",
                    translation: passage.translation,
                    text: bibleStore.selections[passage.selectionKey]?.fullText ?? "Loading...",
                )
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxl)
        }
        .fullScreenCover(isPresented: $showPractice) {
            SessionView(passage: passage)
        }
        .task {
            await bibleStore.fetchSelection(passage.selectionKey)
        }
        .navigationTitle(passage.reference)
        .navigationBarTitleDisplayMode(.inline)
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

}

#Preview("PassageDetailView") {
    NavigationStack {
        PassageDetailView(passage: PreviewData.samplePassage)
    }
    .modelContainer(PreviewData.container)
    .environment(BibleStore.shared)
    .environment(\.font, .app())
}
