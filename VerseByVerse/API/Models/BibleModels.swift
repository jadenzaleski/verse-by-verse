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
