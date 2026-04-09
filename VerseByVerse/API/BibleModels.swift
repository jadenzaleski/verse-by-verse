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
