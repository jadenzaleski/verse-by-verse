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

    /// Probability of recall right now, straight from the FSRS engine — the
    /// same curve that schedules reviews, so the score hits ~90% exactly when
    /// a review comes due.
    private var retentionScore: Double {
        scheduler.retrievability(of: passage.memoryState, at: .now)
    }

    private var dueDateText: String {
        guard let next = passage.nextPractice else {
            return passage.state == 0 ? "New — start your first practice" : "Ready to practice"
        }
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: next),
        ).day ?? 0
        if days < 0 { return "Overdue by \(-days) day\(-days == 1 ? "" : "s")" }
        if days == 0 { return "Due today" }
        return "Due in \(days) day\(days == 1 ? "" : "s")"
    }

    private var dueDateColor: Color {
        guard let next = passage.nextPractice else {
            return passage.state == 0 ? .appAccent : .green
        }
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: next),
        ).day ?? 0
        if days < 0 { return .red }
        if days == 0 { return .orange }
        return .secondary
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                memoryScoreCard
                practiceCard
                historyCard
                passageTextCard
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

    private var memoryScoreCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Memory Score")
                .font(.app(.title2))

            if passage.lastPracticed != nil {
                Text("\(Int(retentionScore * 100))%")
                    .font(.app(.largeTitle, weight: .semibold))
                    .foregroundStyle(retentionScore < 0.6 ? .red : retentionScore < 0.8 ? .orange : .green)
                SegmentedProgressBar(
                    totalSegments: 10,
                    completedSegments: Int(retentionScore * 10),
                    height: 20,
                )
            } else {
                Text("Complete your first practice session to start tracking your memory score.")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: AppSpacing.xl) {
                statItem(label: "Reviews", value: "\(passage.reps)")
                statItem(label: "Missed", value: "\(passage.lapses)")
                if let last = passage.lastPracticed {
                    statItem(label: "Last Practice", value: last.formatted(.relative(presentation: .named)))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private var practiceCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Practice")
                .font(.app(.title2))

            HStack(spacing: AppSpacing.sm) {
                Circle()
                    .fill(dueDateColor)
                    .frame(width: 8, height: 8)
                Text(dueDateText)
                    .font(.app(.subheadline))
                    .foregroundStyle(dueDateColor)
            }

            Button {
                showPractice = true
            } label: {
                Text("Start Practice")
                    .font(.app(.body, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppRadius.md)
                    .background(Color.appAccent, in: RoundedRectangle(cornerRadius: AppRadius.md))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            if let next = passage.nextPractice {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "calendar")
                    Text("Next review: \(next.formatted(.dateTime.month(.abbreviated).day().year()))")
                }
                .font(.app(.caption))
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

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

    private var passageTextCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Passage")
                    .font(.app(.title2))
                Spacer()
                Text(passage.translation)
                    .font(.app(.caption, weight: .semibold))
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(Color.secondary.opacity(0.15), in: Capsule())
                    .foregroundStyle(.secondary)
            }
            Text(bibleStore.selections[passage.selectionKey]?.fullText ?? "Loading...")
                .font(.app(.body))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(value)
                .font(.app(.body, weight: .semibold))
            Text(label)
                .font(.app(.caption))
                .foregroundStyle(.secondary)
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
