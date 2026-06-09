//
//  PassageDetailView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/4/26.
//

import SwiftUI

struct PassageDetailView: View {
    let passage: UserPassage

    @Environment(BibleStore.self) private var bibleStore
    @Environment(PracticeStore.self) private var practiceStore

    @State private var showPractice = false

    private var passageSessions: [PracticeSession] {
        practiceStore.sessions.filter { $0.passageId == passage.id }
    }

    private var retentionScore: Double {
        guard let lastPracticed = passage.lastPracticed else { return 0.0 }
        let daysSince = Date().timeIntervalSince(lastPracticed) / 86400
        return pow(0.9, daysSince / max(1.0, passage.stability))
    }

    private var dueDateText: String {
        guard let next = passage.nextPractice else {
            return passage.state == 0 ? "New — start your first practice" : "Ready to practice"
        }
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: next)
        ).day ?? 0
        if days < 0 { return "Overdue by \(-days) day\(-days == 1 ? "" : "s")" }
        if days == 0 { return "Due today" }
        return "Due in \(days) day\(days == 1 ? "" : "s")"
    }

    private var dueDateColor: Color {
        guard let next = passage.nextPractice else {
            return passage.state == 0 ? .accentColor : .green
        }
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: next)
        ).day ?? 0
        if days < 0 { return .red }
        if days == 0 { return .orange }
        return .secondary
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                memoryScoreCard
                practiceCard
                historyCard
                passageTextCard
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 24)
        }
        .fullScreenCover(isPresented: $showPractice) {
            SessionView(passage: passage)
        }
        .task {
            if practiceStore.sessions.isEmpty {
                await practiceStore.loadMyPracticeSessions()
            }
            await bibleStore.fetchSelection(passage.selectionKey)
        }
    }

    // MARK: - Cards

    private var memoryScoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Score")
                .font(.app(.title2))

            if passage.lastPracticed != nil {
                Text("\(Int(retentionScore * 100))%")
                    .font(.app(.largeTitle, weight: .semibold))
                    .foregroundStyle(retentionScore < 0.6 ? .red : retentionScore < 0.8 ? .orange : .green)
                SegmentedProgressBar(
                    totalSegments: 10,
                    completedSegments: Int(retentionScore * 10),
                    height: 20
                )
            } else {
                Text("Complete your first practice session to start tracking your memory score.")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 20) {
                statItem(label: "Reviews", value: "\(passage.reps)")
                statItem(label: "Missed", value: "\(passage.lapses)")
                if let last = passage.lastPracticed {
                    statItem(label: "Last Practice", value: last.formatted(.relative(presentation: .named)))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    private var practiceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Practice")
                .font(.app(.title2))

            HStack(spacing: 6) {
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
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            if let next = passage.nextPractice {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text("Next review: \(next.formatted(.dateTime.month(.abbreviated).day().year()))")
                }
                .font(.app(.caption))
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private var historyCard: some View {
        if passageSessions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("History")
                    .font(.app(.title2))
                Text("No practice history yet.")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("History")
                    .font(.app(.title2))
                    .padding([.horizontal, .top])
                PassageMemoryScoreChart(sessions: passageSessions)
                    .padding()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private var passageTextCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Passage")
                    .font(.app(.title2))
                Spacer()
                Text(passage.translation)
                    .font(.app(.caption, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15), in: Capsule())
                    .foregroundStyle(.secondary)
            }
            Text(bibleStore.selections[passage.selectionKey]?.fullText ?? "Loading...")
                .font(.app(.body))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.app(.body, weight: .semibold))
            Text(label)
                .font(.app(.caption))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("PassageDetailView") {
    let passage = UserPassage(
        id: 1, userId: "test", book: "John",
        startChapter: 3, endChapter: 3, startVerse: 16, endVerse: 16,
        translation: "KJV",
        lastPracticed: Calendar.current.date(byAdding: .day, value: -2, to: .now),
        nextPractice: Calendar.current.date(byAdding: .day, value: 1, to: .now),
        stability: 4.0, difficulty: 5.2, state: 2,
        reps: 3, lapses: 0, scheduledDays: 3, elapsedDays: 2
    )
    NavigationStack {
        PassageDetailView(passage: passage)
            .navigationTitle(passage.reference)
            .navigationBarTitleDisplayMode(.inline)
    }
    .environment(BibleStore.shared)
    .environment(PassageStore.shared)
    .environment(PracticeStore.shared)
    .environment(\.font, .app())
}
