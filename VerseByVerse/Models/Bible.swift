//
//  Bible.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation
import SwiftUI

struct BibleTranslationInfo: Identifiable, Equatable {
    let id: String
    let abbreviation: String
    let name: String
    let copyright: String
    let provider: String
    /// See `BibleTranslation.requiresAttestation`.
    var requiresAttestation = false
    /// See `BibleTranslation.passageLimit`.
    var passageLimit: PassageLimit?
}

extension BibleTranslationInfo {
    var copyrightText: Text {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        guard let attributed = try? AttributedString(markdown: copyright, options: options) else {
            return Text(copyright)
        }
        return Text(attributed)
    }
}

struct BibleStructure: Equatable {
    let books: [String: [Int]]

    var sortedBookNames: [String] {
        books.keys.sorted()
    }

    func chapters(for book: String) -> Int {
        books[book]?.count ?? 0
    }

    func verses(for book: String, chapter: Int) -> Int {
        guard let chapters = books[book], chapter >= 1, chapter <= chapters.count else {
            return 0
        }
        return chapters[chapter - 1]
    }

    /// Verses spanned by `startChapter:startVerse`–`endChapter:endVerse`
    /// (inclusive), or `nil` when the book or range isn't valid.
    func verseCount(
        book: String,
        startChapter: Int,
        startVerse: Int,
        endChapter: Int,
        endVerse: Int,
    ) -> Int? {
        guard let chapters = books[book],
              startChapter >= 1, endChapter <= chapters.count, startChapter <= endChapter
        else { return nil }
        let whole = chapters[(startChapter - 1) ..< endChapter].reduce(0, +)
        let count = whole - (startVerse - 1) - (chapters[endChapter - 1] - endVerse)
        return count > 0 ? count : nil
    }
}

extension BibleTranslation {
    func toDomain() -> BibleTranslationInfo {
        BibleTranslationInfo(
            id: id,
            abbreviation: abbreviation,
            name: name,
            copyright: copyright,
            provider: provider,
            requiresAttestation: requiresAttestation ?? false,
            passageLimit: passageLimit,
        )
    }
}

extension BibleBooksResponse {
    func toDomain() -> BibleStructure {
        BibleStructure(books: books)
    }
}
