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

    private let booksLoader: () async throws -> BibleBooksResponse
    private let translationsLoader: () async throws -> BibleTranslationsResponse

    private init() {
        booksLoader = { try await APIService.shared.getBibleBooks() }
        translationsLoader = { try await APIService.shared.getBibleTranslations() }
    }

    init(
        booksLoader: @escaping () async throws -> BibleBooksResponse,
        translationsLoader: @escaping () async throws -> BibleTranslationsResponse,
    ) {
        self.booksLoader = booksLoader
        self.translationsLoader = translationsLoader
    }

    /// A store that already holds `selections` and never touches the network,
    /// for previews and tests that need verse text without fetching it.
    @MainActor
    static func offline(selections: [BibleSelection]) -> BibleStore {
        let store = BibleStore(
            booksLoader: { throw URLError(.notConnectedToInternet) },
            translationsLoader: { throw URLError(.notConnectedToInternet) },
        )
        for selection in selections {
            store.selections[selection.key] = selection
        }
        return store
    }

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

    /// Display text for a selection: the verses once loaded, a short failure
    /// message if the fetch failed, otherwise `placeholder` while loading.
    func displayText(for key: BibleSelectionKey, placeholder: String) -> Text {
        if let selection = selections[key] {
            return selection.annotatedText
        }
        if case .error = selectionState(for: key) {
            return Text("Couldn't load verse text.").foregroundStyle(.secondary)
        }
        return Text(placeholder)
    }

    /// Settings' Clear Cache: empties the response cache (disk + memory),
    /// drops the verse text held here, and re-fetches book and translation
    /// metadata, so a translation the server just started (or stopped)
    /// offering shows up without a relaunch. Text cards fetch again when they
    /// next appear; the old metadata stays in place if the re-fetch fails
    /// (offline).
    @MainActor
    func clearCache() async {
        await Cache.shared.removeAll()
        clearSelections()
        async let books: Void = loadBibleData(force: true)
        async let translations: Void = loadTranslations(force: true)
        _ = await (books, translations)
    }

    /// Forgets every fetched selection and its loading state.
    @MainActor
    func clearSelections() {
        selections.removeAll()
        selectionStates.removeAll()
    }

    /// - Parameter force: re-fetch even when already loaded (`clearCache()`).
    @MainActor
    func loadBibleData(force: Bool = false) async {
        // Skip if loaded, or if a load is already in flight (rapid retries);
        // an `.error` state falls through so callers can retry.
        if !force, bibleData != nil, bibleDataState == .success {
            return
        }
        if bibleDataState == .loading {
            return
        }

        bibleDataState = .loading

        do {
            let dataResponse = try await booksLoader()
            bibleData = dataResponse.toDomain()
            bibleDataState = .success
            log.info("Bible data loaded successfully")
        } catch {
            bibleDataState = .error(mapError(error))
            log.error("Failed to load Bible data: \(error.localizedDescription)")
        }
    }

    /// - Parameter force: re-fetch even when already loaded (`clearCache()`).
    @MainActor
    func loadTranslations(force: Bool = false) async {
        // Same guard as `loadBibleData()`: retry on error, not while loading.
        if !force, availableTranslations != nil, translationsState == .success {
            return
        }
        if translationsState == .loading {
            return
        }

        translationsState = .loading

        do {
            let translationsResponse = try await translationsLoader()
            availableTranslations = translationsResponse.map { $0.toDomain() }
            translationsState = .success
            log.info("Bible translations loaded successfully")
        } catch {
            translationsState = .error(mapError(error))
            log.error("Failed to load translations: \(error.localizedDescription)")
        }
    }

    /// The translations a new passage can use: `availableTranslations` minus
    /// licensed ones the server won't serve to an app that can't attest (the
    /// Simulator).
    var selectableTranslations: [BibleTranslationInfo]? {
        availableTranslations?.filter { !$0.requiresAttestation || AppAttestClient.shared.isSupported }
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
                provider: "",
            )
    }

    /// The translation's `passageLimit` violation for a range, or `nil` when
    /// the range is within it (or the translation has no cap, or metadata
    /// hasn't loaded — the server still enforces the cap).
    func passageLimitViolation(
        translation: String,
        book: String,
        startChapter: Int,
        startVerse: Int,
        endChapter: Int,
        endVerse: Int,
    ) -> PassageLimitViolation? {
        guard let limit = translationInfo(forAbbreviation: translation).passageLimit,
              let chapters = bibleData?.books[book],
              let requested = bibleData?.verseCount(
                  book: book,
                  startChapter: startChapter,
                  startVerse: startVerse,
                  endChapter: endChapter,
                  endVerse: endVerse,
              )
        else { return nil }
        let allowed = limit.maxVerses(forChapterVerseCounts: chapters)
        guard requested > allowed else { return nil }
        return PassageLimitViolation(translation: translation, book: book, requested: requested, allowed: allowed)
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

/// A range longer than its translation allows in one request (see
/// `BibleStore.passageLimitViolation`).
struct PassageLimitViolation: Equatable {
    let translation: String
    let book: String
    let requested: Int
    let allowed: Int

    var message: String {
        "The \(translation) allows at most \(allowed) verses of \(book) at a time (\(requested) selected)."
    }
}
