//
//  MemoryScoreCard.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/13/26.
//

import SwiftUI

/// The detail screens' summary card: Memory Score with its bar, when the
/// material is next due, and the last result / session / last-practice
/// stats. Practice itself starts from ``PracticeStartButton`` and ``PracticeToolbar``.
struct MemoryScoreCard: View {
    let lastPracticed: Date?
    let totalReps: Int
    let retentionScore: Double
    /// What you got last practice (0…1), shown as a plain fact beside the estimate.
    let lastResult: Double?
    let nextPracticeDate: Date?
    let isNew: Bool

    private var scoreColor: Color {
        retentionScore < 0.6 ? .red : retentionScore < 0.8 ? .orange : .green
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
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text("Memory Score")
                    .font(.app(.title2))
                Spacer()
                dueBadge
            }

            if lastPracticed != nil {
                HStack(spacing: AppSpacing.md) {
                    Text("\(Int(retentionScore * 100))%")
                        .font(.app(.title, weight: .semibold))
                        .foregroundStyle(scoreColor)
                        .monospacedDigit()
                    SegmentedProgressBar(
                        totalSegments: 10,
                        completedSegments: Int(retentionScore * 10),
                        accessibilityLabel: "Memory score",
                        height: 16,
                    )
                }
                stats
            } else {
                Text("Practice once to start tracking your memory score.")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
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

    private var stats: some View {
        HStack(spacing: AppSpacing.lg) {
            if let lastResult {
                statItem(label: "Last Result", value: "\(Int((lastResult * 100).rounded()))%")
            }
            statItem(label: totalReps == 1 ? "Session" : "Sessions", value: "\(totalReps)")
            if let last = lastPracticed {
                statItem(label: "Last Practice", value: last.formatted(.relative(presentation: .named)))
            }
        }
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(value)
                .font(.app(.body, weight: .semibold))
            Text(label)
                .font(.app(.caption))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
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
