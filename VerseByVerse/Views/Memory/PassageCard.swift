//
//  PassageCard.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 2/8/26.
//

import SwiftUI

struct PassageCard: View {
    @Environment(BibleStore.self) private var bibleStore
    let passage: UserPassage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(passage.reference)
                    .font(.app(weight: .semibold))
                Spacer()
                Text(passage.translation)
                    .environment(\.font, .app(.caption))
            }

            Text(bibleStore.selections[passage.selectionKey]?.fullText ?? "...")
                .lineLimit(2)
                .font(.app(.subheadline))

            SegmentedProgressBar(
                totalSegments: 10,
                completedSegments: min(passage.reps, 10),
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
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        .task {
            await bibleStore.fetchSelection(passage.selectionKey)
        }
    }

    private var dueText: String {
        guard let next = passage.nextPractice else { return "Not scheduled" }
        let days = Calendar.current.dateComponents([.day], from: .now, to: next).day ?? 0
        if days > 0 { return "Due in \(days) day\(days == 1 ? "" : "s")" }
        if days == 0 { return "Due today" }
        return "Overdue \(-days) day\(-days == 1 ? "" : "s")"
    }

    private var lastPracticedText: String {
        guard let last = passage.lastPracticed else { return "Never practiced" }
        let days = Calendar.current.dateComponents([.day], from: last, to: .now).day ?? 0
        if days == 0 { return "Practiced today" }
        return "\(days) day\(days == 1 ? "" : "s") ago"
    }
}

#Preview {
    PassageCard(passage: UserPassage(id: 1,
                                     userId: "test",
                                     book: "John",
                                     startChapter: 1,
                                     endChapter: 2,
                                     startVerse: 3,
                                     endVerse: 4,
                                     translation: "KJV",
                                     lastPracticed: nil,
                                     nextPractice: nil,
                                     stability: 1.0,
                                     difficulty: 1.0,
                                     state: 1,
                                     reps: 1,
                                     lapses: 1,
                                     scheduledDays: 1,
                                     elapsedDays: 1))
        .padding()
        .environment(\.font, .app())
}
