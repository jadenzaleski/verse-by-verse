//
//  BibleStore.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 3/6/26.
//

import Observation
import SwiftUI

@Observable
final class BibleStore {
    static let shared = BibleStore()

    private(set) var bibleData: BibleBooksResponse?
    private(set) var state: DataState = .idle
    private(set) var lastError: APIError?

    private let log = AppLog.category("BibleStore")

    private init() {}

    /// The list of Bible books in traditional biblical order.
    let bibleBooksOrder = [
        "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
        "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel",
        "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles",
        "Ezra", "Nehemiah", "Esther", "Job", "Psalms",
        "Proverbs", "Ecclesiastes", "Song of Solomon", "Isaiah",
        "Jeremiah", "Lamentations", "Ezekiel", "Daniel",
        "Hosea", "Joel", "Amos", "Obadiah", "Jonah",
        "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai",
        "Zechariah", "Malachi", "Matthew", "Mark", "Luke",
        "John", "Acts", "Romans", "1 Corinthians", "2 Corinthians",
        "Galatians", "Ephesians", "Philippians", "Colossians",
        "1 Thessalonians", "2 Thessalonians", "1 Timothy", "2 Timothy",
        "Titus", "Philemon", "Hebrews", "James", "1 Peter",
        "2 Peter", "1 John", "2 John", "3 John", "Jude", "Revelation",
    ]

    @MainActor
    func loadBibleData() async {
        // If we already have data, don't reload unless state is error
        if bibleData != nil, state == .success { return }

        state = .loading
        lastError = nil

        do {
            let data = try await APIService.shared.getBibleBooks()
            bibleData = data
            state = .success
            log.info("Bible data loaded successfully")
        } catch let apiError as APIError {
            self.lastError = apiError
            self.state = .error(apiError)
            log.error("Failed to load Bible data: \(apiError.localizedDescription)")
        } catch {
            let unknownError = APIError.unknown(underlying: error)
            lastError = unknownError
            state = .error(unknownError)
            log.error("Unknown error loading Bible data: \(error.localizedDescription)")
        }
    }

    /// Returns the number of chapters for a given book name.
    func chapterCount(for book: String) -> Int {
        bibleData?.chapters(for: book) ?? 0
    }

    /// Returns the number of verses for a given book and chapter.
    func verseCount(for book: String, chapter: Int) -> Int {
        bibleData?.verses(for: book, chapter: chapter) ?? 0
    }

    /// Validates if a chapter exists for a book.
    func isValidChapter(_ chapter: Int, for book: String) -> Bool {
        let count = chapterCount(for: book)
        return chapter >= 1 && chapter <= count
    }

    /// Validates if a verse exists for a book and chapter.
    func isValidVerse(_ verse: Int, for book: String, chapter: Int) -> Bool {
        let count = verseCount(for: book, chapter: chapter)
        return verse >= 1 && verse <= count
    }
}
