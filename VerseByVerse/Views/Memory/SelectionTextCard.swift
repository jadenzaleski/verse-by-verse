//
//  SelectionTextCard.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/8/26.
//

import SwiftUI

/// The verse/passage text card on a detail screen: fetches the selection's
/// text, and offers a retry (manual, and automatic once back online) when
/// that fetch fails.
struct SelectionTextCard: View {
    let title: String
    let translation: String
    let key: BibleSelectionKey
    /// The verses shown, whose reviews feed the missed-word heatmap.
    let verses: [Verse]

    @Environment(BibleStore.self) private var bibleStore

    private var hasFailed: Bool {
        bibleStore.selectionState(for: key).apiError != nil
    }

    private var heatmap: HeatmapData? {
        bibleStore.selections[key].map { WordHeatmap.build(selection: $0, verses: verses) }
    }

    var body: some View {
        LongTextCard(
            title: title,
            translation: bibleStore.translationInfo(forAbbreviation: translation),
            text: bibleStore.displayText(for: key, placeholder: "Loading..."),
            onRetry: hasFailed ? { Task { await load() } } : nil,
            heatmap: heatmap,
        )
        .task { await load() }
        .retryWhenOnline(if: hasFailed) { await load() }
        .retryAfterRateLimit(error: { bibleStore.selectionState(for: key).apiError }, perform: { await load() })
        .task(id: bibleStore.selections[key] != nil) {
            guard let selection = bibleStore.selections[key] else { return }
            FUMSReporter.shared.report(tokens: selection.fumsTokens)
        }
    }

    private func load() async {
        await bibleStore.fetchSelection(key)
    }
}
