//
//  BibleStoreLoadingTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 10/8/26.
//

import Foundation
import Testing
@testable import VerseByVerse

/// First launch with no network: metadata loads fail, surface as `.error`, and
/// recover on retry (the Add screen's "Try Again" / back-online path).
@MainActor
@Suite("Bible store loading")
struct BibleStoreLoadingTests {
    /// Fails until `isOnline` flips, then serves a tiny Bible.
    private final class FlakyBackend {
        var isOnline = false
        var booksCalls = 0

        func books() async throws -> BibleBooksResponse {
            booksCalls += 1
            guard isOnline else { throw APIError.network(underlying: URLError(.notConnectedToInternet)) }
            return BibleBooksResponse(books: ["John": [51, 25, 36]])
        }

        func translations() async throws -> BibleTranslationsResponse {
            guard isOnline else { throw APIError.network(underlying: URLError(.notConnectedToInternet)) }
            return [BibleTranslation(id: "kjv", abbreviation: "KJV", name: "King James", copyright: "", provider: "")]
        }
    }

    private func makeStore(_ backend: FlakyBackend) -> BibleStore {
        BibleStore(booksLoader: backend.books, translationsLoader: backend.translations)
    }

    @Test func `offline load lands in error with no data`() async {
        let store = makeStore(FlakyBackend())
        await store.loadBibleData()
        await store.loadTranslations()

        #expect(store.bibleDataState == .error(.cancelled))
        #expect(store.translationsState == .error(.cancelled))
        #expect(store.bibleData == nil)
        #expect(store.chapterCount(for: "John") == 0)
    }

    @Test func `retry after going online succeeds`() async {
        let backend = FlakyBackend()
        let store = makeStore(backend)
        await store.loadBibleData()
        await store.loadTranslations()

        backend.isOnline = true
        await store.loadBibleData()
        await store.loadTranslations()

        #expect(store.bibleDataState == .success)
        #expect(store.translationsState == .success)
        #expect(store.chapterCount(for: "John") == 3)
        #expect(store.availableTranslations?.first?.abbreviation == "KJV")
    }

    @Test func `successful load is not repeated`() async {
        let backend = FlakyBackend()
        backend.isOnline = true
        let store = makeStore(backend)
        await store.loadBibleData()
        await store.loadBibleData()

        #expect(backend.booksCalls == 1)
    }

    @Test func `overlapping loads share one request`() async {
        let backend = FlakyBackend()
        backend.isOnline = true
        let store = makeStore(backend)
        async let first: Void = store.loadBibleData()
        async let second: Void = store.loadBibleData()
        _ = await (first, second)

        #expect(backend.booksCalls == 1)
        #expect(store.bibleDataState == .success)
    }
}
