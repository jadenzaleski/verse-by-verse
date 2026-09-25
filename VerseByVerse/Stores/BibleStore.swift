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

    private(set) var bibleData: BibleStructure?
    private(set) var availableTranslations: [BibleTranslationInfo]?
    private(set) var selections: [BibleSelectionKey: BibleSelection] = [:]

    /// Independent per-resource loading state. `loadBibleData()`,
    /// `loadTranslations()`, and `fetchSelection()` are unrelated,
    /// concurrently-triggered operations (startup warms metadata while a
    /// detail view fetches a selection); sharing one `state` field let
    /// whichever finished last stomp the others' loading/error signal.
    private(set) var bibleDataState: DataState = .idle
    private(set) var translationsState: DataState = .idle
    private(set) var selectionStates: [BibleSelectionKey: DataState] = [:]

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

    /// Loading/error state for a specific selection fetch. Views should read
    /// this instead of a shared field so unrelated selections (or metadata
    /// loads) can't clobber each other's signal.
    func selectionState(for key: BibleSelectionKey) -> DataState {
        selectionStates[key] ?? .idle
    }

    @MainActor
    func loadBibleData() async {
        // If we already have data, don't reload unless state is error
        if bibleData != nil, bibleDataState == .success { return }

        bibleDataState = .loading

        do {
            let dataResponse = try await APIService.shared.getBibleBooks()
            bibleData = dataResponse.toDomain()
            bibleDataState = .success
            log.info("Bible data loaded successfully")
        } catch {
            bibleDataState = .error(mapError(error))
            log.error("Failed to load Bible data: \(error.localizedDescription)")
        }
    }

    @MainActor
    func loadTranslations() async {
        // If we already have translations, don't reload unless state is error
        if availableTranslations != nil, translationsState == .success { return }

        translationsState = .loading

        do {
            let translationsResponse = try await APIService.shared.getBibleTranslations()
            availableTranslations = translationsResponse.map { $0.toDomain() }
            translationsState = .success
            log.info("Bible translations loaded successfully")
        } catch {
            translationsState = .error(mapError(error))
            log.error("Failed to load translations: \(error.localizedDescription)")
        }
    }

    /// Resolves an abbreviation (as stored on `Verse`/`Passage`) to its full
    /// translation info. Falls back to a copyright-less placeholder when
    /// translations haven't loaded yet or the abbreviation isn't recognized.
    func translationInfo(forAbbreviation abbreviation: String) -> BibleTranslationInfo {
        availableTranslations?.first { $0.abbreviation == abbreviation }
            ?? BibleTranslationInfo(
                id: abbreviation,
                abbreviation: abbreviation,
                name: abbreviation,
                copyright: "",
                provider: "")
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

    @MainActor
    func fetchSelection(_ key: BibleSelectionKey, strip: Bool = true, forceRefresh: Bool = false) async {
        // Check cache first, unless the caller explicitly wants a fresh remote fetch
        if !forceRefresh, selections[key] != nil {
            selectionStates[key] = .success
            return
        }

        selectionStates[key] = .loading

        do {
            let passageResponse = try await APIService.shared.getBibleSelection(
                translation: key.translation,
                start: key.startRef,
                end: key.endRef,
                strip: strip,
                lookInCache: !forceRefresh,
            )
            let selection = passageResponse.toDomain()
            selections[key] = selection
            selectionStates[key] = .success
            log.info("BibleSelection fetched and cached: \(key)")
        } catch {
            selectionStates[key] = .error(mapError(error))
            log.error("Failed to fetch selection \(key): \(error.localizedDescription)")
        }
    }

    private func mapError(_ error: Error) -> APIError {
        (error as? APIError) ?? .unknown(underlying: error)
    }
}
