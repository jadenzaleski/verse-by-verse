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

    @Environment(BibleStore.self) private var bibleStore

    private var hasFailed: Bool {
        bibleStore.selectionState(for: key).apiError != nil
    }

    var body: some View {
        LongTextCard(
            title: title,
            translation: bibleStore.translationInfo(forAbbreviation: translation),
            text: bibleStore.displayText(for: key, placeholder: "Loading..."),
            onRetry: hasFailed ? { Task { await load() } } : nil,
        )
        .task { await load() }
        .retryWhenOnline(if: hasFailed) { await load() }
    }

    private func load() async {
        await bibleStore.fetchSelection(key)
    }
}
