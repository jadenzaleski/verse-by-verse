//
//  FUMSReporterTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 10/10/26.
//

import Foundation
import Testing
@testable import VerseByVerse

/// API.Bible FUMS reporting: one anonymous beacon per scripture display,
/// carrying the tokens the Bible proxy returned with the text.
@Suite("FUMS reporter")
struct FUMSReporterTests {
    /// Collects the URLs the reporter would have requested.
    private final class Recorder: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: [URL] = []

        var urls: [URL] {
            lock.withLock { stored }
        }

        func record(_ url: URL) {
            lock.withLock { stored.append(url) }
        }
    }

    private func makeReporter(_ recorder: Recorder) -> FUMSReporter {
        FUMSReporter(deviceId: "device-1", sessionId: "session-1", send: { recorder.record($0) })
    }

    private func queryItems(_ url: URL) -> [URLQueryItem] {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    }

    @Test func `beacon targets the FUMS v3 endpoint with device and session ids`() async {
        let recorder = Recorder()
        await makeReporter(recorder).report(tokens: ["tok-a"])?.value

        let url = try? #require(recorder.urls.first)
        #expect(url?.absoluteString.hasPrefix("https://fums.api.bible/f3?") == true)
        let items = url.map(queryItems) ?? []
        #expect(items.contains(URLQueryItem(name: "dId", value: "device-1")))
        #expect(items.contains(URLQueryItem(name: "sId", value: "session-1")))
        #expect(items.contains(URLQueryItem(name: "t", value: "tok-a")))
    }

    @Test func `multiple tokens share one request as repeated t params`() async {
        let recorder = Recorder()
        await makeReporter(recorder).report(tokens: ["tok-a", "tok-b"])?.value

        #expect(recorder.urls.count == 1)
        let tokens = recorder.urls.first.map(queryItems)?.filter { $0.name == "t" }.map(\.value)
        #expect(tokens == ["tok-a", "tok-b"])
    }

    @Test func `tokens are percent-encoded`() async {
        let recorder = Recorder()
        await makeReporter(recorder).report(tokens: ["a+b&c=d"])?.value

        let url = recorder.urls.first
        #expect(url?.absoluteString.contains("t=a%2Bb%26c%3Dd") == true)
    }

    @Test func `no tokens sends nothing`() {
        let recorder = Recorder()
        let task = makeReporter(recorder).report(tokens: [])

        #expect(task == nil)
        #expect(recorder.urls.isEmpty)
    }

    @Test func `blank tokens are ignored`() {
        let recorder = Recorder()
        let task = makeReporter(recorder).report(tokens: ["", "  "])

        #expect(task == nil)
        #expect(recorder.urls.isEmpty)
    }

    @Test func `device id is created once and then reused`() throws {
        let suite = "FUMSReporterTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let first = FUMSReporter.persistedDeviceId(in: defaults)
        let second = FUMSReporter.persistedDeviceId(in: defaults)

        #expect(!first.isEmpty)
        #expect(first == second)
        #expect(defaults.string(forKey: StorageKeys.fumsDeviceId.rawValue) == first)
    }

    @Test func `selection response carries fums tokens into the domain model`() {
        let response = BibleSelectionResponse(
            translation: "NIV",
            verses: [BibleVerse(book: "John", chapter: 3, verse: 16, text: "For God so loved the world")],
            fumsTokens: ["tok-a"],
            book: "John",
            startChapter: 3,
            endChapter: 3,
            startVerse: 16,
            endVerse: 16,
        )

        #expect(response.toDomain().fumsTokens == ["tok-a"])
    }

    @Test func `public domain selection has no fums tokens`() {
        let response = BibleSelectionResponse(
            translation: "KJV",
            verses: [],
            fumsTokens: nil,
            book: "John",
            startChapter: 3,
            endChapter: 3,
            startVerse: 16,
            endVerse: 16,
        )

        #expect(response.toDomain().fumsTokens.isEmpty)
    }
}
