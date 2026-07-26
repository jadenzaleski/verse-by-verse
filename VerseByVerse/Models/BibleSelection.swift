//
//  BibleSelection.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation
import SwiftUI
import UIKit

struct SelectionVerse: Identifiable, Equatable {
    let id: String
    let book: String
    let chapter: Int
    let verse: Int
    let text: String
}

struct BibleSelectionKey: Hashable, Codable {
    let translation: String
    let book: String
    let startChapter: Int
    let startVerse: Int
    let endChapter: Int
    let endVerse: Int

    init(translation: String, book: String, startChapter: Int, startVerse: Int, endChapter: Int, endVerse: Int) {
        self.translation = translation.uppercased()
        self.book = book.uppercased()
        self.startChapter = startChapter
        self.startVerse = startVerse
        self.endChapter = endChapter
        self.endVerse = endVerse
    }

    var startRef: String {
        "\(book) \(startChapter):\(startVerse)"
    }

    var endRef: String? {
        if startChapter == endChapter, startVerse == endVerse { return nil }
        return "\(book) \(endChapter):\(endVerse)"
    }
}

struct BibleSelection: Equatable {
    let translation: String
    let book: String
    let startChapter: Int
    let startVerse: Int
    let endChapter: Int
    let endVerse: Int
    let verses: [SelectionVerse]

    var key: BibleSelectionKey {
        BibleSelectionKey(
            translation: translation,
            book: book,
            startChapter: startChapter,
            startVerse: startVerse,
            endChapter: endChapter,
            endVerse: endVerse,
        )
    }

    var fullText: String {
        verses.map(\.text).joined(separator: " ")
    }

    /// Verse text with superscript verse numbers interleaved — use this for all
    /// read-only display. `fullText` is reserved for session word-mapping logic.
    var annotatedText: Text {
        Text(numberedAttributedString()).font(.bible())
    }

    /// Same as `annotatedText`, but appends the passage's reference (e.g.
    /// "- John 3:16-18") once at the end — used during practice-session
    /// recite so the passage stays anchored to its reference while spoken aloud.
    var annotatedTextWithReference: Text {
        var result = numberedAttributedString()
        var ref = AttributedString(" - \(reference)")
        ref.swiftUI.font = .bible(.callout)
        ref.swiftUI.foregroundColor = Color.secondary
        result += ref
        return Text(result).font(.bible())
    }

    private func numberedAttributedString() -> AttributedString {
        var result = AttributedString()
        for (index, selectionVerse) in verses.enumerated() {
            if index > 0 {
                result += AttributedString(" ")
            }
            var num = AttributedString("\(selectionVerse.verse)")
            num.swiftUI.font = .bible(.caption2)
            num.swiftUI.foregroundColor = Color.secondary
            num.uiKit.baselineOffset = UIFontMetrics(forTextStyle: .caption2).scaledValue(for: 5)
            result += num
            result += AttributedString(" \(selectionVerse.text)")
        }
        return result
    }

    var reference: String {
        if startChapter == endChapter {
            if startVerse == endVerse {
                "\(book) \(startChapter):\(startVerse)"
            } else {
                "\(book) \(startChapter):\(startVerse)-\(endVerse)"
            }
        } else {
            "\(book) \(startChapter):\(startVerse)-\(endChapter):\(endVerse)"
        }
    }
}

extension BibleVerse {
    func toDomain() -> SelectionVerse {
        SelectionVerse(id: id, book: book, chapter: chapter, verse: verse, text: text)
    }
}

extension BibleSelectionResponse {
    func toDomain() -> BibleSelection {
        BibleSelection(
            translation: translation,
            book: book,
            startChapter: startChapter,
            startVerse: startVerse,
            endChapter: endChapter,
            endVerse: endVerse,
            verses: verses.map { $0.toDomain() },
        )
    }
}
