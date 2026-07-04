//
//  ReferenceFooterView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/4/26.
//

import SwiftUI

struct ReferenceFooterView: View {
    @Environment(BibleStore.self) private var bibleStore
    let startChapter: String
    let selectedBook: String

    var body: some View {
        HStack {
            if bibleStore.state == .loading {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 15, height: 15)
            }

            if let chapter = Int(startChapter), bibleStore.isValidChapter(chapter, for: selectedBook) {
                let verseCount = bibleStore.verseCount(for: selectedBook, chapter: chapter)
                Text("\(selectedBook) \(chapter) has \(verseCount) verses.")
            } else {
                let chapterCount = bibleStore.chapterCount(for: selectedBook)
                Text("\(selectedBook) has \(chapterCount) chapters.")
            }
        }
        .font(.app(.footnote))
    }
}
