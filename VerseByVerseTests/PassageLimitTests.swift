//
//  PassageLimitTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 10/31/26.
//

import Foundation
import Testing
@testable import VerseByVerse

/// The ESV's per-request cap: the server advertises `passage_limit`, the Add
/// screen blocks ranges over it, and a `400 PASSAGE_TOO_LONG` that still gets
/// through reads as a sentence, not a code.
@MainActor
@Suite("Passage limit")
struct PassageLimitTests {
    private let esvLimit = PassageLimit(maxVerses: 500, halfBook: true)

    /// Genesis (50 chapters, 1,533 verses), Ruth (4 chapters, 85), Jude (1, 25).
    private static let books: [String: [Int]] = [
        "Genesis": [31, 25, 24, 26, 32, 22, 24, 22, 29, 32, 32, 20, 18, 24, 21, 16, 27, 33, 38, 18,
                    34, 24, 20, 67, 34, 35, 46, 22, 35, 43, 55, 32, 20, 31, 29, 43, 36, 30, 23, 23,
                    57, 38, 34, 34, 28, 34, 31, 22, 33, 26],
        "Ruth": [22, 23, 18, 22],
        "Jude": [25],
    ]

    private func makeStore() async -> BibleStore {
        let store = BibleStore(
            booksLoader: { BibleBooksResponse(books: Self.books) },
            translationsLoader: {
                [
                    BibleTranslation(
                        id: "ESV", abbreviation: "ESV", name: "English Standard Version",
                        copyright: "", provider: "ESV API", requiresAttestation: false,
                        passageLimit: PassageLimit(maxVerses: 500, halfBook: true),
                    ),
                    BibleTranslation(
                        id: "kjv", abbreviation: "KJV", name: "King James Version",
                        copyright: "", provider: "local", requiresAttestation: false, passageLimit: nil,
                    ),
                ]
            },
        )
        await store.loadBibleData()
        await store.loadTranslations()
        return store
    }

    // MARK: - Decoding

    @Test func `passage limit decodes from the server's snake case`() throws {
        let json = Data("""
        {"id": "ESV", "abbreviation": "ESV", "name": "English Standard Version",
         "copyright": "", "provider": "ESV API", "requires_attestation": false,
         "passage_limit": {"max_verses": 500, "half_book": true}}
        """.utf8)
        let translation = try JSONDecoder().decode(BibleTranslation.self, from: json)
        #expect(translation.passageLimit == PassageLimit(maxVerses: 500, halfBook: true))
    }

    @Test func `older servers without a passage limit still decode`() throws {
        let json = Data("""
        {"id": "kjv", "abbreviation": "KJV", "name": "King James Version",
         "copyright": "", "provider": "local"}
        """.utf8)
        let translation = try JSONDecoder().decode(BibleTranslation.self, from: json)
        #expect(translation.passageLimit == nil)
    }

    // MARK: - The rule (mirrors the server's `PassageLimit.max_verses_for`)

    @Test func `half book caps long books below the verse maximum only when smaller`() throws {
        #expect(try esvLimit.maxVerses(forChapterVerseCounts: #require(Self.books["Genesis"])) == 500)
        #expect(try esvLimit.maxVerses(forChapterVerseCounts: #require(Self.books["Ruth"])) == 85 / 2)
    }

    @Test func `books with one or two chapters are exempt from the half book rule`() {
        #expect(esvLimit.maxVerses(forChapterVerseCounts: [25]) == 500)
        #expect(esvLimit.maxVerses(forChapterVerseCounts: [10, 10]) == 500)
    }

    @Test func `without half book only the verse maximum applies`() {
        let limit = PassageLimit(maxVerses: 500, halfBook: false)
        #expect(limit.maxVerses(forChapterVerseCounts: [22, 23, 18, 22]) == 500)
    }

    // MARK: - Verse counting

    @Test func `verse count spans chapters inclusively`() {
        let bible = BibleStructure(books: Self.books)
        #expect(bible.verseCount(book: "Ruth", startChapter: 1, startVerse: 1, endChapter: 1, endVerse: 1) == 1)
        #expect(bible.verseCount(book: "Ruth", startChapter: 1, startVerse: 1, endChapter: 1, endVerse: 22) == 22)
        // Ruth 1:20 – 2:3 = 3 + 3
        #expect(bible.verseCount(book: "Ruth", startChapter: 1, startVerse: 20, endChapter: 2, endVerse: 3) == 6)
        #expect(bible.verseCount(book: "Ruth", startChapter: 1, startVerse: 1, endChapter: 4, endVerse: 22) == 85)
    }

    @Test func `verse count rejects unknown books and reversed ranges`() {
        let bible = BibleStructure(books: Self.books)
        #expect(bible.verseCount(book: "Hezekiah", startChapter: 1, startVerse: 1, endChapter: 1, endVerse: 2) == nil)
        #expect(bible.verseCount(book: "Ruth", startChapter: 2, startVerse: 1, endChapter: 1, endVerse: 2) == nil)
        #expect(bible.verseCount(book: "Ruth", startChapter: 1, startVerse: 5, endChapter: 1, endVerse: 4) == nil)
    }

    // MARK: - Store check

    @Test func `range over the cap is a violation with a readable message`() async {
        let store = await makeStore()
        let violation = store.passageLimitViolation(
            translation: "ESV", book: "Ruth", startChapter: 1, startVerse: 1, endChapter: 2, endVerse: 23,
        )
        #expect(violation == PassageLimitViolation(translation: "ESV", book: "Ruth", requested: 45, allowed: 42))
        #expect(violation?.message == "The ESV allows at most 42 verses of Ruth at a time (45 selected).")
    }

    @Test func `range exactly at the cap is allowed`() async {
        let store = await makeStore()
        // Ruth's cap is 42: 1:1 – 2:20 = 22 + 20 is exactly at it, one more is over.
        #expect(store.passageLimitViolation(
            translation: "ESV", book: "Ruth", startChapter: 1, startVerse: 1, endChapter: 2, endVerse: 20,
        ) == nil)
        #expect(store.passageLimitViolation(
            translation: "ESV", book: "Ruth", startChapter: 1, startVerse: 1, endChapter: 2, endVerse: 21,
        ) != nil)
    }

    @Test func `translations without a cap never violate`() async {
        let store = await makeStore()
        #expect(store.passageLimitViolation(
            translation: "KJV", book: "Genesis", startChapter: 1, startVerse: 1, endChapter: 50, endVerse: 26,
        ) == nil)
    }

    @Test func `whole one chapter book is allowed`() async {
        let store = await makeStore()
        #expect(store.passageLimitViolation(
            translation: "ESV", book: "Jude", startChapter: 1, startVerse: 1, endChapter: 1, endVerse: 25,
        ) == nil)
    }

    // MARK: - Server backstop

    private func response(_ status: Int, retryAfter: String? = nil) throws -> HTTPURLResponse {
        let url = try #require(URL(string: "https://example.com/bible"))
        let headers = retryAfter.map { ["Retry-After": $0] }
        return try #require(HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: headers))
    }

    @Test func `passage too long drops the code and reads as a sentence`() throws {
        let detail = "PASSAGE_TOO_LONG: the ESV can be requested at most 42 verses of Ruth at a time (45 requested)."
        let error = try APIError.from(response: response(400), detail: detail, data: nil)
        guard case let .passageTooLong(message) = error else {
            Issue.record("Expected .passageTooLong, got \(error)")
            return
        }
        #expect(message == "The ESV can be requested at most 42 verses of Ruth at a time (45 requested).")
        #expect(error.statusCode == 400)
    }

    @Test func `passage too long counts as the server answering`() {
        #expect(NetworkMonitor.classify(.passageTooLong(message: nil)) == .online)
    }

    @Test func `other 400s stay plain http errors`() throws {
        let error = try APIError.from(response: response(400), detail: "Translation 'xyz' is not supported.", data: nil)
        guard case .http(400, "Translation 'xyz' is not supported.", _) = error else {
            Issue.record("Expected .http(400), got \(error)")
            return
        }
    }
}
