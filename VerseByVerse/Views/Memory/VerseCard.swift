//
//  VerseCard.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/10/26.
//

import SwiftData
import SwiftUI

/// List card for a tracked verse — mirrors `PassageCard`'s layout.
struct VerseCard: View {
    let verse: Verse

    private let scheduler = FSRSScheduler()

    /// Probability of recall right now — the same curve that schedules
    /// reviews, not a raw rep count.
    private var retentionScore: Double {
        scheduler.retrievability(of: verse.memoryState, at: .now)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text(verse.reference)
                    .font(.app(weight: .semibold))
                if !verse.addedDirectly {
                    Text("in \(verse.passages?.count ?? 0) passage\((verse.passages?.count ?? 0) == 1 ? "" : "s")")
                        .font(.app(.caption))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Text(verse.translation)
                    .environment(\.font, .app(.caption))
            }

            SegmentedProgressBar(
                totalSegments: 10,
                completedSegments: Int(retentionScore * 10),
            )

            HStack {
                Text(dueText)
                Spacer()
                Text(lastPracticedText)
            }
            .environment(\.font, .app(.caption))
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private var dueText: String {
        guard let next = verse.nextPractice else {
            return verse.isNew ? "New" : "Not scheduled"
        }
        let days = Calendar.current.dateComponents([.day], from: .now, to: next).day ?? 0
        if days > 0 { return "Due in \(days) day\(days == 1 ? "" : "s")" }
        if days == 0 { return "Due today" }
        return "Overdue \(-days) day\(-days == 1 ? "" : "s")"
    }

    private var lastPracticedText: String {
        guard let last = verse.lastPracticed else { return "Never practiced" }
        let days = Calendar.current.dateComponents([.day], from: last, to: .now).day ?? 0
        if days == 0 { return "Practiced today" }
        return "\(days) day\(days == 1 ? "" : "s") ago"
    }
}

#Preview {
    VerseCard(verse: PreviewData.sampleVerse)
        .modelContainer(PreviewData.container)
        .padding()
        .environment(\.font, .app())
}
