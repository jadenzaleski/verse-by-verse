//
//  FSRSScheduler.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/7/26.
//

import Foundation
import FSRS

/// FSRS-6 implementation of ``MemoryScheduler`` over the official
/// `open-spaced-repetition/swift-fsrs` package: FSRS-6 default 21 weights,
/// fuzzing disabled so scheduling is deterministic, and no review scheduled
/// more than ``maximumIntervalDays`` out.
/// Fine-tuning (per-user parameters, custom retention UI) can come later.
nonisolated struct FSRSScheduler: MemoryScheduler {
    /// The longest gap before a verse is due again. FSRS is tuned on flashcards, where
    /// perfect recall grows intervals to hundreds of days; for verses we want them back
    /// at least monthly. It caps the due date only — stability, and so the Memory
    /// Score's decay curve, is unchanged. Applied here rather than through the
    /// library's `maximumInterval`, which still lets an Easy result land a day past it.
    static let maximumIntervalDays = 30.0

    private let engine: FSRS
    private let log = AppLog.category("FSRSScheduler")

    init(desiredRetention: Double = 0.95) {
        engine = FSRS(parameters: FSRSParameters(
            requestRetention: desiredRetention,
            w: FSRSDefaults.defaultWv6,
            enableFuzz: false,
            enableShortTerm: false,
        ))
    }

    func processReview(state: MemoryState, score: Double, at date: Date) -> ReviewOutcome {
        let rating = MemoryScoring.rating(forScore: score)
        let card = makeCard(from: state, now: date)

        let updated: Card
        do {
            // Rating is always 1…4 here; `.manual` (the only throwing input) is unreachable.
            updated = try engine.next(card: card, now: date, grade: Rating(rawValue: rating) ?? .again).card
        } catch {
            assertionFailure("FSRS review failed: \(error)")
            log.error("FSRS review failed, keeping previous state: \(error)")
            return ReviewOutcome(state: state, rating: rating, intervalDays: 0)
        }

        let due = min(updated.due, date.addingTimeInterval(Self.maximumIntervalDays * 86400))

        let newState = MemoryState(
            stability: updated.stability,
            difficulty: updated.difficulty,
            state: updated.state.rawValue,
            step: updated.learningSteps,
            due: due,
            lastReviewed: date,
            reps: state.reps + 1,
            // VBV counts every Again as a lapse (spec of the retired backend),
            // regardless of the card state it happened in.
            lapses: state.lapses + (rating == 1 ? 1 : 0),
        )

        return ReviewOutcome(
            state: newState,
            rating: rating,
            intervalDays: due.timeIntervalSince(date) / 86400.0,
        )
    }

    func retrievability(of state: MemoryState, at date: Date) -> Double {
        guard state.state != 0 else { return 0 }
        // No stability means nothing is retained. Left to the library, 0 ÷ 0 gives NaN
        // (and a negative stability gives nonsense), which would crash `Int(score * 100)`.
        guard let stability = state.stability, stability > 0 else { return 0 }
        return engine.getRetrievability(card: makeCard(from: state, now: date), now: date).number
    }

    /// Maps the persisted ``MemoryState`` onto an FSRS `Card`.
    private func makeCard(from state: MemoryState, now: Date) -> Card {
        guard state.state != 0, state.lastReviewed != nil else {
            // Never practiced: a fresh card takes the initial-stability path.
            return Card(due: now, state: .new)
        }
        return Card(
            due: state.due ?? now,
            stability: state.stability ?? 0,
            difficulty: state.difficulty ?? 0,
            learningSteps: state.step,
            reps: state.reps,
            lapses: state.lapses,
            state: CardState(rawValue: state.state) ?? .new,
            lastReview: state.lastReviewed,
        )
    }
}
