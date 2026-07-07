//
//  MemoryScheduler.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/7/26.
//

import Foundation

/// Snapshot of a passage's spaced-repetition memory state.
///
/// This is the only shape the app persists for scheduling; any engine that
/// can turn a `MemoryState` + a session score into a new `MemoryState`
/// (via ``MemoryScheduler``) can drive the practice loop.
struct MemoryState: Equatable, Codable {
    /// FSRS stability in days; `nil` until the first review.
    var stability: Double?
    /// FSRS difficulty (1–10); `nil` until the first review.
    var difficulty: Double?
    /// Card state: 0 = new, 1 = learning, 2 = review, 3 = relearning.
    var state: Int
    /// Index into the learning/relearning steps; meaningful only in states 1 and 3.
    var step: Int
    /// When the next review is scheduled; `nil` until the first review.
    var due: Date?
    /// When the passage was last reviewed; `nil` until the first review.
    var lastReviewed: Date?
    /// Total completed reviews.
    var reps: Int
    /// Times the passage was forgotten (rated Again).
    var lapses: Int

    /// State for a passage that has never been practiced.
    static let new = MemoryState(
        stability: nil, difficulty: nil,
        state: 0, step: 0,
        due: nil, lastReviewed: nil,
        reps: 0, lapses: 0,
    )
}

/// Result of applying one completed practice session to a passage.
struct ReviewOutcome: Equatable {
    var state: MemoryState
    /// FSRS rating derived from the session score: 1 = Again … 4 = Easy.
    var rating: Int
    /// Days from the review to the next due date.
    var intervalDays: Double
}

/// The seam between VerseByVerse and any scheduling engine.
protocol MemoryScheduler {
    /// Applies one completed session (score 0…1) to a passage's memory state.
    func processReview(state: MemoryState, score: Double, at date: Date) -> ReviewOutcome

    /// Probability of recall right now (0…1) — drives the Memory Score UI.
    func retrievability(of state: MemoryState, at date: Date) -> Double
}

enum MemoryScoring {
    /// Session score → FSRS rating. Thresholds are part of the VBV memory
    /// spec (pinned by the parity fixtures): ≥0.90 Easy, ≥0.80 Good,
    /// ≥0.60 Hard, else Again.
    static func rating(forScore score: Double) -> Int {
        if score >= 0.90 { return 4 }
        if score >= 0.80 { return 3 }
        if score >= 0.60 { return 2 }
        return 1
    }
}
