//
//  BibleModels.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 3/6/26.
//

import Foundation

struct BibleBooksResponse: Codable {
    let books: [String: [Int]]

    /// Returns the sorted list of book names.
    var sortedBookNames: [String] {
        // Since it's a JSON object, the keys are not guaranteed to be in biblical order.
        // We might want to provide a hardcoded order if order matters.
        // For now, let's just return them sorted alphabetically or check if the JSON has a specific order.
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
}

struct BibleTranslation: Codable, Equatable {
    let id, abbreviation, name, copyright, provider: String
}

typealias BibleTranslationsResponse = [BibleTranslation]

struct BibleVerse: Codable, Identifiable, Equatable {
    var id: String { "\(book) \(chapter):\(verse)" }
    let book: String
    let chapter: Int
    let verse: Int
    let text: String
}

struct BiblePassageResponse: Codable {
    let translation: String
    let verses: [BibleVerse]
    let fumsTokens: [String]?
    let book: String
    let startChapter: Int
    let endChapter: Int
    let startVerse: Int
    let endVerse: Int

    enum CodingKeys: String, CodingKey {
        case translation, verses, book
        case fumsTokens = "fums_tokens"
        case startChapter = "start_chapter"
        case endChapter = "end_chapter"
        case startVerse = "start_verse"
        case endVerse = "end_verse"
    }

    var fullText: String {
        verses.map { $0.text }.joined(separator: " ")
    }
}
