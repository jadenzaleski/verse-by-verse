//
//  PassageCard.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 2/8/26.
//

import SwiftData
import SwiftUI

enum PassageCardStyle {
    case full
    case compact
}

struct PassageCard: View {
    @Environment(BibleStore.self) private var bibleStore
    let passage: Passage
    var style: PassageCardStyle = .full

    private let scheduler = FSRSScheduler()

    /// Average probability of recall across the passage's verses — the same
    /// curve that schedules reviews, not raw rep counts.
    private var retentionScore: Double {
        passage.memoryScore(using: scheduler) ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text(passage.reference)
                    .font(.app(weight: .semibold))
                Spacer()
                Text(passage.translation)
                    .environment(\.font, .app(.caption))
            }

            if style == .full {
                bibleStore.displayText(for: passage.selectionKey, placeholder: "...")
                    .lineLimit(2)
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
        .task { await loadText() }
        .retryWhenOnline(if: bibleStore.selectionState(for: passage.selectionKey).apiError != nil) {
            await loadText()
        }
    }

    private func loadText() async {
        if style == .full {
            await bibleStore.fetchSelection(passage.selectionKey)
        }
    }

    private var dueText: String {
        guard let next = passage.nextPractice else { return "Not scheduled" }
        return DueText.precise(to: next)
    }

    private var lastPracticedText: String {
        guard let last = passage.lastPracticed else { return "Never practiced" }
        let days = Calendar.current.dateComponents([.day], from: last, to: .now).day ?? 0
        if days == 0 { return "Practiced today" }
        return "\(days) day\(days == 1 ? "" : "s") ago"
    }
}

#Preview {
    PassageCard(passage: PreviewData.samplePassage)
        .modelContainer(PreviewData.container)
        .padding()
        .environment(BibleStore.shared)
        .environment(\.font, .app())
}
