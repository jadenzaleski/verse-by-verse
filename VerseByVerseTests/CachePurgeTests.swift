//
//  CachePurgeTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 11/2/26.
//

import Foundation
import Testing
@testable import VerseByVerse

/// Verse text may be stored for at most 14 days. Entries expire lazily when
/// read, so a launch-time purge removes the ones nobody asks for again.
@MainActor
@Suite("Cache purge")
struct CachePurgeTests {
    private struct Payload: Codable, Equatable {
        let text: String
    }

    private func makeCache() throws -> (Cache, URL) {
        let dir = FileManager.default.temporaryDirectory
            .appending(path: "vbv-cache-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        return (Cache(directory: dir), dir)
    }

    private func store(_ cache: Cache, key: String, ttl: TimeInterval?) async {
        await cache.set(key: key, response: APIResponse(statusCode: 200, body: Payload(text: key)), ttl: ttl)
    }

    private func files(in dir: URL) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: dir.path).sorted()
    }

    @Test func `purge removes expired entries and keeps fresh ones`() async throws {
        let (cache, dir) = try makeCache()
        defer { try? FileManager.default.removeItem(at: dir) }
        await store(cache, key: "old", ttl: 10)
        await store(cache, key: "fresh", ttl: 1000)

        // 100s from now: "old" has expired, "fresh" has not.
        let removed = await cache.purgeExpired(now: Date().addingTimeInterval(100))

        #expect(removed == 1)
        #expect(try files(in: dir) == ["fresh"])
        #expect(await cache.get("old", decode: Payload.self) == nil)
        #expect(await cache.get("fresh", decode: Payload.self)?.body == Payload(text: "fresh"))
    }

    @Test func `purge drops expired entries from memory too`() async throws {
        let (cache, dir) = try makeCache()
        defer { try? FileManager.default.removeItem(at: dir) }
        await store(cache, key: "old", ttl: 10)

        await cache.purgeExpired(now: Date().addingTimeInterval(100))

        // Not yet expired by the real clock, so only a purged memory layer
        // and disk make this a miss.
        #expect(await cache.get("old", decode: Payload.self) == nil)
    }

    @Test func `purge removes files that are not readable entries`() async throws {
        let (cache, dir) = try makeCache()
        defer { try? FileManager.default.removeItem(at: dir) }
        try Data("not json".utf8).write(to: dir.appending(path: "garbage"))
        await store(cache, key: "fresh", ttl: 1000)

        let removed = await cache.purgeExpired()

        #expect(removed == 1)
        #expect(try files(in: dir) == ["fresh"])
    }

    @Test func `purge keeps entries that never expire`() async throws {
        let (cache, dir) = try makeCache()
        defer { try? FileManager.default.removeItem(at: dir) }
        await store(cache, key: "forever", ttl: nil)

        let removed = await cache.purgeExpired(now: Date().addingTimeInterval(365 * 24 * 60 * 60))

        #expect(removed == 0)
        #expect(try files(in: dir) == ["forever"])
    }

    @Test func `purging an empty cache is harmless`() async throws {
        let (cache, dir) = try makeCache()
        defer { try? FileManager.default.removeItem(at: dir) }
        #expect(await cache.purgeExpired() == 0)
    }
}
