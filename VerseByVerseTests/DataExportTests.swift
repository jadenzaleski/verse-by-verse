//
//  DataExportTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 11/2/26.
//

import Foundation
import SwiftData
import Testing
@testable import VerseByVerse

/// "Export My Data": the library as portable JSON — references and memory
/// state only, never verse text.
@MainActor
@Suite("Data export")
struct DataExportTests {
    private let container = AppModelContainer.make(inMemory: true)
    private let reviewDate = Date(timeIntervalSince1970: 1_767_268_800) // 2026-01-01T12:00:00Z
    private let exportDate = Date(timeIntervalSince1970: 1_767_355_200) // 2026-01-02T12:00:00Z

    private func john316Ref(_ number: Int) -> DataExport.VerseRef {
        DataExport.VerseRef(translation: "KJV", book: "John", chapter: 3, number: number)
    }

    /// John 3:16-17 reviewed once in a completed session, a set holding the
    /// passage, plus one standalone verse (Psalm 23:1) with a standalone session.
    private func seed(_ context: ModelContext) throws {
        let passage = Passage(book: "John", startChapter: 3, endChapter: 3, startVerse: 16, endVerse: 17)
        context.insert(passage)
        let verses = try (16 ... 17).map {
            try Verse.findOrCreate(translation: "KJV", book: "John", chapter: 3, number: $0, in: context)
        }
        passage.verses = verses

        let set = StudySet(name: "Favorites", setDescription: "Gospel", meshTheme: .forest)
        set.passages = [passage]
        context.insert(set)

        let scheduler = FSRSScheduler()
        let session = PracticeSession(startDate: reviewDate.addingTimeInterval(-120))
        session.endDate = reviewDate
        session.score = 0.92
        session.rating = 3
        session.passage = passage
        context.insert(session)
        let activity = PracticeActivity(position: 0, type: "Verbal Recite", correctCount: 9, totalCount: 10)
        activity.session = session
        context.insert(activity)
        for verse in verses {
            let outcome = scheduler.processReview(state: verse.memoryState, score: 0.92, at: reviewDate)
            verse.memoryState = outcome.state
            let review = VerseReview(reviewedAt: reviewDate)
            review.rating = outcome.rating
            review.score = 0.92
            review.stabilityAfter = outcome.state.stability ?? 0
            review.verse = verse
            review.session = session
        }

        let standalone = try Verse.findOrCreate(translation: "ESV", book: "Psalms", chapter: 23, number: 1, in: context)
        standalone.addedDirectly = true
        let standaloneSession = PracticeSession(startDate: reviewDate.addingTimeInterval(3600))
        standaloneSession.standaloneVerse = standalone
        context.insert(standaloneSession)
        try context.save()
    }

    private func makeExport() throws -> DataExport {
        let context = container.mainContext
        try seed(context)
        return try DataExport.make(from: context, now: exportDate, appVersion: "1.2.3")
    }

    // MARK: - Content

    @Test func `an empty library exports empty lists`() throws {
        let export = try DataExport.make(from: container.mainContext, now: exportDate, appVersion: "1.2.3")
        #expect(export.schemaVersion == DataExport.currentSchemaVersion)
        #expect(export.appVersion == "1.2.3")
        #expect(export.verses.isEmpty && export.passages.isEmpty && export.sets.isEmpty && export.sessions.isEmpty)
    }

    @Test func `verses carry memory state and their review log, in reference order`() throws {
        let export = try makeExport()
        #expect(export.verses.map(\.verse) == [
            john316Ref(16),
            john316Ref(17),
            DataExport.VerseRef(translation: "ESV", book: "Psalms", chapter: 23, number: 1),
        ].sorted())

        let john316 = try #require(export.verses.first { $0.verse == john316Ref(16) })
        #expect(john316.reps == 1)
        #expect(john316.stability != nil)
        #expect(john316.reviews.count == 1)
        #expect(john316.reviews[0].reviewedAt == reviewDate)
        #expect(john316.reviews[0].score == 0.92)
        #expect(john316.reviews[0].sessionStartedAt == reviewDate.addingTimeInterval(-120))

        let psalm = try #require(export.verses.first { $0.verse.book == "Psalms" })
        #expect(psalm.addedDirectly)
        #expect(psalm.reps == 0)
        #expect(psalm.reviews.isEmpty)
    }

    @Test func `passages and sets link to verses and passages by reference`() throws {
        let export = try makeExport()

        let passage = try #require(export.passages.first)
        #expect(passage.passage == DataExport.PassageRef(
            translation: "KJV", book: "John", startChapter: 3, startVerse: 16, endChapter: 3, endVerse: 17,
        ))
        #expect(passage.verses == [john316Ref(16), john316Ref(17)])

        let set = try #require(export.sets.first)
        #expect(set.name == "Favorites")
        #expect(set.description == "Gospel")
        #expect(set.theme == "forest")
        #expect(set.passages == [passage.passage])
    }

    @Test func `sessions keep their activities and what they practiced`() throws {
        let export = try makeExport()
        #expect(export.sessions.count == 2)

        let passageSession = try #require(export.sessions.first { $0.passage != nil })
        #expect(passageSession.verse == nil)
        #expect(passageSession.endDate == reviewDate)
        #expect(passageSession.rating == 3)
        #expect(passageSession.activities.map(\.type) == ["Verbal Recite"])
        #expect(passageSession.activities.first?.correctCount == 9)

        let standaloneSession = try #require(export.sessions.first { $0.verse != nil })
        #expect(standaloneSession.passage == nil)
        #expect(standaloneSession.verse?.book == "Psalms")
        #expect(standaloneSession.endDate == nil)
    }

    // MARK: - JSON

    @Test func `json round trips and is identical for identical data`() throws {
        let export = try makeExport()
        let data = try export.jsonData()
        // Dates are stored to the millisecond, so compare the re-encoded
        // form rather than the in-memory values.
        #expect(try DataExport.decode(data).jsonData() == data)
        #expect(try DataExport.decode(data).verses.count == export.verses.count)
        #expect(try DataExport.make(from: container.mainContext, now: exportDate, appVersion: "1.2.3")
            .jsonData() == data)
    }

    @Test func `json is readable and tagged with a schema version`() throws {
        let json = try #require(String(bytes: makeExport().jsonData(), encoding: .utf8))
        #expect(json.contains("\"schemaVersion\" : 1"))
        #expect(json.contains("\"appVersion\" : \"1.2.3\""))
        #expect(json.contains("\"exportedAt\" : \"2026-01-02T12:00:00"))
        #expect(json.contains("\n")) // pretty printed
    }

    @Test func `the export never contains verse text`() throws {
        let json = try #require(String(bytes: makeExport().jsonData(), encoding: .utf8)).lowercased()
        #expect(!json.contains("\"text\""))
        #expect(!json.contains("for god so loved"))
    }

    // MARK: - File

    @Test func `the file is named for the export day and holds the json`() throws {
        let export = try makeExport()
        let url = try export.writeTemporaryFile()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        #expect(url.lastPathComponent == "VerseByVerse-Export-2026-01-02.json")
        #expect(try Data(contentsOf: url) == export.jsonData())
    }

    @Test func `the file can be written off the main actor`() async throws {
        let export = try makeExport()
        let url = try await Task.detached { try export.writeTemporaryFile() }.value
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        #expect(try Data(contentsOf: url) == export.jsonData())
    }

    @Test func `writing again leaves only the newest export behind`() throws {
        let first = try makeExport()
        let firstURL = try first.writeTemporaryFile()
        var second = first
        second.exportedAt = exportDate.addingTimeInterval(86400 * 3)
        let secondURL = try second.writeTemporaryFile()
        defer { try? FileManager.default.removeItem(at: secondURL.deletingLastPathComponent()) }

        #expect(!FileManager.default.fileExists(atPath: firstURL.path))
        #expect(FileManager.default.fileExists(atPath: secondURL.path))
    }
}
