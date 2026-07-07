//
//  PracticeSession.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/16/26.
//

import Foundation
import SwiftData

/// One completed (or abandoned mid-write) practice session for a passage.
///
/// Sessions are the append-only source of truth for practice history; the
/// passage's `MemoryState` is derived from them and can be rebuilt by replay.
/// CloudKit-compatible by design: defaults everywhere, optional relationships.
@Model
final class PracticeSession {
    var startDate: Date = Date()
    var endDate: Date?
    /// Overall score 0…1 across the session's activities.
    var score: Double?
    /// FSRS rating derived from the score: 1 = Again … 4 = Easy.
    var rating: Int?
    /// Days FSRS scheduled until the next review, at completion time.
    var scheduledDays: Int?
    /// Actual days elapsed since the previous review, at completion time.
    var elapsedDays: Int?
    /// FSRS card state at the time of the review.
    var state: Int?
    /// Record-format version for future lazy migrations (CloudKit is additive-only).
    var schemaVersion: Int = 1

    var passage: Passage?

    @Relationship(deleteRule: .cascade, inverse: \PracticeActivity.session)
    var activities: [PracticeActivity]? = []

    init(startDate: Date = Date()) {
        self.startDate = startDate
    }

    var isCompleted: Bool {
        endDate != nil
    }
}

/// One activity within a practice session (e.g. "Every Other Word", phase 0).
@Model
final class PracticeActivity {
    /// Order of this activity within its session.
    var position: Int = 0
    var type: String = ""
    var phase: Int?
    var isRetry: Bool = false
    var correctCount: Int = 0
    var totalCount: Int = 0
    var startDate: Date = Date()
    var endDate: Date = Date()

    var session: PracticeSession?

    init(
        position: Int = 0,
        type: String = "",
        phase: Int? = nil,
        isRetry: Bool = false,
        correctCount: Int = 0,
        totalCount: Int = 0,
        startDate: Date = Date(),
        endDate: Date = Date(),
    ) {
        self.position = position
        self.type = type
        self.phase = phase
        self.isRetry = isRetry
        self.correctCount = correctCount
        self.totalCount = totalCount
        self.startDate = startDate
        self.endDate = endDate
    }
}
