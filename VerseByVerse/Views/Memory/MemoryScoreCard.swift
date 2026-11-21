//
//  MemoryScoreCard.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/13/26.
//

import SwiftUI

/// The detail screens' summary card: Memory Score with its bar, when the
/// material is next due, and a one-line last result / session / last-practice
/// summary. Practice itself starts from ``PracticeStartButton`` and ``PracticeToolbar``.
struct MemoryScoreCard: View {
    let lastPracticed: Date?
    let totalReps: Int
    let retentionScore: Double
    /// What you got last practice (0…1), shown as a plain fact beside the estimate.
    let lastResult: Double?
    let nextPracticeDate: Date?
    let isNew: Bool

    private var scoreColor: Color {
        .score(retentionScore)
    }

    private var dueText: String {
        guard let next = nextPracticeDate else {
            return isNew ? "New" : "Ready to practice"
        }
        return DueText.precise(to: next)
    }

    private var dueColor: Color {
        guard let next = nextPracticeDate else {
            return isNew ? .appAccent : .green
        }
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: .now), to: calendar.startOfDay(for: next),
        ).day ?? 0
        if days < 0 {
            return .red
        }
        return days == 0 ? .orange : .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text("Memory Score")
                    .font(.app(.headline))
                Spacer()
                dueBadge
            }

            if let lastPracticed {
                HStack(spacing: AppSpacing.sm) {
                    Text("\(Int(retentionScore * 100))%")
                        .font(.app(.headline, weight: .semibold))
                        .foregroundStyle(scoreColor)
                        .monospacedDigit()
                    SegmentedProgressBar(
                        totalSegments: 10,
                        completedSegments: Int(retentionScore * 10),
                        fill: scoreColor,
                        accessibilityLabel: "Memory score",
                        height: 8,
                    )
                }
                summary(lastPracticed: lastPracticed)
            } else {
                Text("Practice once to start tracking your memory score.")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private var dueBadge: some View {
        HStack(spacing: AppSpacing.xs) {
            Circle()
                .fill(dueColor)
                .frame(width: 8, height: 8)
            Text(dueText)
                .font(.app(.subheadline))
                .foregroundStyle(dueColor)
        }
        .accessibilityElement(children: .combine)
    }

    /// Summary text.
    private func summary(lastPracticed: Date) -> some View {
        var parts: [String] = []
        if let lastResult {
            parts.append("Last \(Int((lastResult * 100).rounded()))%")
        }
        parts.append(totalReps == 1 ? "1 session" : "\(totalReps) sessions")
        parts.append(lastPracticed.formatted(.relative(presentation: .named)))
        let dot = Image("lucide.dot")
        let line = parts.dropFirst().reduce(Text(parts[0])) { line, part in
            Text("\(line)\(dot)\(part)")
        }
        return line
            .font(.app(.footnote))
            .foregroundStyle(.secondary)
    }
}

#Preview {
    VStack {
        MemoryScoreCard(
            lastPracticed: PreviewData.samplePassage.lastPracticed,
            totalReps: PreviewData.samplePassage.totalReps,
            retentionScore: 0.75,
            lastResult: 0.92,
            nextPracticeDate: PreviewData.samplePassage.nextPractice,
            isNew: false,
        )
        MemoryScoreCard(
            lastPracticed: nil, totalReps: 0, retentionScore: 0, lastResult: nil, nextPracticeDate: nil, isNew: true,
        )
    }
    .padding(.horizontal, AppSpacing.md)
    .environment(\.font, .app())
}
