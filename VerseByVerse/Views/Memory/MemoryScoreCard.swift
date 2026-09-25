//
//  MemoryScoreCard.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/13/26.
//

import SwiftUI

struct MemoryScoreCard: View {
    let lastPracticed: Date?
    let totalReps: Int
    let retentionScore: Double

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Memory Score")
                .font(.app(.title2))

            if lastPracticed != nil {
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
                let sessionLabel = totalReps >= 2 ? "Sessions" : "Session"
                statItem(label: sessionLabel, value: "\(totalReps)")
                if let last = lastPracticed {
                    statItem(label: "Last Practice", value: last.formatted(.relative(presentation: .named)))
                }
            }
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

#Preview {
    MemoryScoreCard(
        lastPracticed: PreviewData.samplePassage.lastPracticed,
        totalReps: PreviewData.samplePassage.totalReps,
        retentionScore: 0.75)
}
