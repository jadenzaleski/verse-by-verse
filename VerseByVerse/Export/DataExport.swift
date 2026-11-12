//
//  DataExport.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/2/26.
//

import Foundation
import SwiftData

/// A portable copy of everything the user has built: verses with their FSRS
/// memory state and review log, passages, study sets, and practice sessions.
///
/// Records point at each other by reference, not by database identity.
/// Bump ``currentSchemaVersion`` whenever the shape changes.
nonisolated struct DataExport: Codable, Equatable {
    static let currentSchemaVersion = 1

    var schemaVersion = DataExport.currentSchemaVersion
    var exportedAt: Date
    var appVersion: String
    var verses: [VerseRecord]
    var passages: [PassageRecord]
    var sets: [SetRecord]
    var sessions: [SessionRecord]
}

// MARK: - Records

extension DataExport {
    /// Identifies a verse card: one per (translation, book, chapter, number).
    nonisolated struct VerseRef: Codable, Hashable, Comparable {
        var translation: String
        var book: String
        var chapter: Int
        var number: Int

        static func < (lhs: Self, rhs: Self) -> Bool {
            (lhs.translation, lhs.book, lhs.chapter, lhs.number)
                < (rhs.translation, rhs.book, rhs.chapter, rhs.number)
        }
    }

    /// Identifies a passage: one per translation and verse range.
    nonisolated struct PassageRef: Codable, Hashable, Comparable {
        var translation: String
        var book: String
        var startChapter: Int
        var startVerse: Int
        var endChapter: Int
        var endVerse: Int

        static func < (lhs: Self, rhs: Self) -> Bool {
            (lhs.translation, lhs.book, lhs.startChapter, lhs.startVerse, lhs.endChapter, lhs.endVerse)
                < (rhs.translation, rhs.book, rhs.startChapter, rhs.startVerse, rhs.endChapter, rhs.endVerse)
        }
    }

    nonisolated struct ReviewRecord: Codable, Equatable {
        var reviewedAt: Date
        var correctCount: Int
        var totalCount: Int
        var score: Double
        /// FSRS rating applied: 1 = Again … 4 = Easy.
        var rating: Int
        var stabilityAfter: Double
        var difficultyAfter: Double
        /// Card state after the review (0…3).
        var stateAfter: Int
        /// Word positions missed (never the words) and the fingerprint of the text they belong to.
        var missedWordIndices: [Int]
        var textFingerprint: String
        /// `startDate` of the session this review came from, if any.
        var sessionStartedAt: Date?
    }

    nonisolated struct VerseRecord: Codable, Equatable {
        var verse: VerseRef
        var addedDirectly: Bool
        var createdAt: Date
        var lastPracticed: Date?
        var nextPractice: Date?
        var stability: Double?
        var difficulty: Double?
        /// 0 = new, 1 = learning, 2 = review, 3 = relearning.
        var state: Int
        var step: Int
        var reps: Int
        var lapses: Int
        var reviews: [ReviewRecord]
    }

    nonisolated struct PassageRecord: Codable, Equatable {
        var passage: PassageRef
        var createdAt: Date
        var verses: [VerseRef]
    }

    nonisolated struct SetRecord: Codable, Equatable {
        var name: String
        var description: String?
        var theme: String
        var meshPositionSeed: Int
        var meshColorSeed: Int
        var createdAt: Date
        var modifiedAt: Date
        var passages: [PassageRef]
        var verses: [VerseRef]
    }

    nonisolated struct ActivityRecord: Codable, Equatable {
        var position: Int
        var type: String
        var phase: Int?
        var isRetry: Bool
        var correctCount: Int
        var totalCount: Int
        var startDate: Date
        var endDate: Date
    }

    nonisolated struct SessionRecord: Codable, Equatable {
        var startDate: Date
        var endDate: Date?
        var score: Double?
        var rating: Int?
        var scheduledDays: Int?
        var elapsedDays: Int?
        var state: Int?
        var passage: PassageRef?
        /// Set when the session practiced a single standalone verse.
        var verse: VerseRef?
        var activities: [ActivityRecord]
    }
}

// MARK: - Building from the library

extension DataExport.VerseRef {
    init(_ verse: Verse) {
        self.init(translation: verse.translation, book: verse.book, chapter: verse.chapter, number: verse.number)
    }
}

extension DataExport.PassageRef {
    init(_ passage: Passage) {
        self.init(
            translation: passage.translation,
            book: passage.book,
            startChapter: passage.startChapter,
            startVerse: passage.startVerse,
            endChapter: passage.endChapter,
            endVerse: passage.endVerse,
        )
    }
}

extension DataExport {
    /// Snapshots the whole library. Ordering is deterministic (by reference,
    /// then date) so two exports of the same data are byte-identical.
    @MainActor
    static func make(
        from context: ModelContext,
        now: Date = .now,
        appVersion: String = Self.currentAppVersion,
    ) throws -> DataExport {
        let verses = try context.fetch(FetchDescriptor<Verse>())
            .map(verseRecord)
            .sorted { $0.verse < $1.verse }

        let passages = try context.fetch(FetchDescriptor<Passage>())
            .map { passage in
                PassageRecord(
                    passage: PassageRef(passage),
                    createdAt: passage.createdAt,
                    verses: (passage.verses ?? []).map(VerseRef.init).sorted(),
                )
            }
            .sorted { ($0.passage, $0.createdAt) < ($1.passage, $1.createdAt) }

        let sets = try context.fetch(FetchDescriptor<StudySet>())
            .map { set in
                SetRecord(
                    name: set.name,
                    description: set.setDescription,
                    theme: set.meshTheme.rawValue,
                    meshPositionSeed: set.meshPositionSeed,
                    meshColorSeed: set.meshColorSeed,
                    createdAt: set.createdAt,
                    modifiedAt: set.modifiedAt,
                    passages: (set.passages ?? []).map(PassageRef.init).sorted(),
                    verses: (set.verses ?? []).map(VerseRef.init).sorted(),
                )
            }
            .sorted { ($0.createdAt, $0.name) < ($1.createdAt, $1.name) }

        let sessions = try context.fetch(FetchDescriptor<PracticeSession>())
            .map(sessionRecord)
            .sorted { $0.startDate < $1.startDate }

        return DataExport(
            exportedAt: now,
            appVersion: appVersion,
            verses: verses,
            passages: passages,
            sets: sets,
            sessions: sessions,
        )
    }

    @MainActor
    private static func verseRecord(_ verse: Verse) -> VerseRecord {
        VerseRecord(
            verse: VerseRef(verse),
            addedDirectly: verse.addedDirectly,
            createdAt: verse.createdAt,
            lastPracticed: verse.lastPracticed,
            nextPractice: verse.nextPractice,
            stability: verse.stability,
            difficulty: verse.difficulty,
            state: verse.state,
            step: verse.step,
            reps: verse.reps,
            lapses: verse.lapses,
            reviews: (verse.reviews ?? [])
                .map { review in
                    ReviewRecord(
                        reviewedAt: review.reviewedAt,
                        correctCount: review.correctCount,
                        totalCount: review.totalCount,
                        score: review.score,
                        rating: review.rating,
                        stabilityAfter: review.stabilityAfter,
                        difficultyAfter: review.difficultyAfter,
                        stateAfter: review.stateAfter,
                        missedWordIndices: review.missedWordIndices.sorted(),
                        textFingerprint: review.textFingerprint,
                        sessionStartedAt: review.session?.startDate,
                    )
                }
                .sorted { $0.reviewedAt < $1.reviewedAt },
        )
    }

    @MainActor
    private static func sessionRecord(_ session: PracticeSession) -> SessionRecord {
        SessionRecord(
            startDate: session.startDate,
            endDate: session.endDate,
            score: session.score,
            rating: session.rating,
            scheduledDays: session.scheduledDays,
            elapsedDays: session.elapsedDays,
            state: session.state,
            passage: session.passage.map(PassageRef.init),
            verse: session.standaloneVerse.map(VerseRef.init),
            activities: (session.activities ?? [])
                .map { activity in
                    ActivityRecord(
                        position: activity.position,
                        type: activity.type,
                        phase: activity.phase,
                        isRetry: activity.isRetry,
                        correctCount: activity.correctCount,
                        totalCount: activity.totalCount,
                        startDate: activity.startDate,
                        endDate: activity.endDate,
                    )
                }
                .sorted { $0.position < $1.position },
        )
    }

    nonisolated static var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }
}

// MARK: - JSON and files

nonisolated extension DataExport {
    /// Pretty-printed with sorted keys, so the file is readable and diffs cleanly.
    /// Dates are ISO-8601 to the millisecond.
    func jsonData() throws -> Data {
        let encoder = JSONEncoder.vbv
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> DataExport {
        try JSONDecoder.vbv.decode(DataExport.self, from: data)
    }

    /// `VerseByVerse-Export-2026-11-02.json`
    func suggestedFileName() -> String {
        let day = exportedAt.formatted(
            Date.ISO8601FormatStyle(dateSeparator: .dash, timeZone: .current).year().month().day(),
        )
        return "VerseByVerse-Export-\(day).json"
    }

    /// Writes the export into a private temporary folder and returns its URL.
    /// Does disk I/O, so call it off the main actor.
    /// Earlier exports are removed first, so at most one copy of the user's
    /// history sits in temporary storage at a time.
    func writeTemporaryFile() throws -> URL {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appending(path: "vbv-export", directoryHint: .isDirectory)
        try? fileManager.removeItem(at: directory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: suggestedFileName())
        try jsonData().write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }
}
