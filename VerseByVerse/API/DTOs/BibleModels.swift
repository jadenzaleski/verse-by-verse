//
//  BibleModels.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 3/6/26.
//

import Foundation

struct BibleBooksResponse: Codable {
    let books: [String: [Int]]
}

struct BibleTranslation: Codable, Equatable {
    let id, abbreviation, name, copyright, provider: String
    /// True when this server currently withholds the translation from apps
    /// that can't attest (licensed text while App Attest is enforced).
    /// Absent from older servers and cached responses.
    let requiresAttestation: Bool?
    /// Per-request size cap for licensed text (the ESV); requests over it get
    /// `400 PASSAGE_TOO_LONG`. Absent when the translation has no cap, and
    /// from older servers and cached responses.
    let passageLimit: PassageLimit?

    enum CodingKeys: String, CodingKey {
        case id, abbreviation, name, copyright, provider
        case requiresAttestation = "requires_attestation"
        case passageLimit = "passage_limit"
    }
}

/// How much of a translation one request may ask for, as the server
/// advertises it (the server owns the rule; the app only mirrors it to block
/// a passage before asking).
struct PassageLimit: Codable, Equatable {
    let maxVerses: Int
    /// Also cap at half the book's verses (rounded down); books with one or
    /// two chapters are exempt.
    let halfBook: Bool

    enum CodingKeys: String, CodingKey {
        case maxVerses = "max_verses"
        case halfBook = "half_book"
    }

    /// The cap for a book, given its per-chapter verse counts.
    func maxVerses(forChapterVerseCounts chapters: [Int]) -> Int {
        guard halfBook, chapters.count > 2 else { return maxVerses }
        return min(maxVerses, chapters.reduce(0, +) / 2)
    }
}

typealias BibleTranslationsResponse = [BibleTranslation]

struct BibleVerse: Codable, Identifiable, Equatable {
    let book: String
    let chapter: Int
    let verse: Int
    let text: String

    var id: String {
        "\(book) \(chapter):\(verse)"
    }
}

struct BibleSelectionResponse: Codable {
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
}
