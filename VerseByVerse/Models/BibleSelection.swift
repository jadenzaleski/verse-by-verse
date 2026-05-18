//
//  BibleSelection.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

struct Verse: Identifiable, Equatable {
    let id: String
    let book: String
    let chapter: Int
    let verse: Int
    let text: String
}

struct BibleSelection: Equatable {
    let translation: String
    let book: String
    let startChapter: Int
    let startVerse: Int
    let endChapter: Int
    let endVerse: Int
    let verses: [Verse]

    var fullText: String {
        verses.map(\.text).joined(separator: " ")
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
    func toDomain() -> Verse {
        Verse(id: id, book: book, chapter: chapter, verse: verse, text: text)
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
