//
//  SessionPlan.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/8/26.
//

import Foundation

nonisolated enum ActivityStep: Equatable {
    case everyOtherWord(phase: Int)
    case everyWord(allowsRetry: Bool)
    case everyWordRetry
    case verbalRecite
}

nonisolated extension ActivityStep {
    /// The standard practice plan, in execution order. This is the plan the
    /// retired backend returned from `/practice-session/start`.
    static let standardPlan: [ActivityStep] = [
        .verbalRecite,
        .everyOtherWord(phase: 0),
        .everyOtherWord(phase: 1),
        .everyWord(allowsRetry: true),
    ]

    var activityType: String {
        switch self {
        case .everyOtherWord: "Every Other Word"
        case .everyWord, .everyWordRetry: "Every Word"
        case .verbalRecite: "Verbal Recite"
        }
    }

    /// One line for the session outline: what the step asks of you.
    var outlineDetail: String {
        switch self {
        case .verbalRecite: "Optional. Say the verse aloud."
        case let .everyOtherWord(phase): phase == 0
            ? "Type the first letter of every odd word."
            : "Type the first letter of every even word."
        case .everyWord: "Type the first letter of every word."
        case .everyWordRetry: "Type it again if you missed any words."
        }
    }

    /// Title for the session outline (the retry reads as its own step).
    var outlineTitle: String {
        isRetry ? "Retry" : activityType
    }

    /// SF Symbol for the session outline.
    var outlineSymbol: String {
        switch self {
        case .verbalRecite: "mic.fill"
        case .everyOtherWord: "circle.lefthalf.fill"
        case .everyWord: "circle.fill"
        case .everyWordRetry: "circle.dotted"
        }
    }

    /// Short tag for the session outline.
    var outlineTag: String {
        switch self {
        case .verbalRecite, .everyWord: "Scored"
        case .everyOtherWord: "Practice"
        case .everyWordRetry: "If needed"
        }
    }

    var phase: Int? {
        if case let .everyOtherWord(phase) = self {
            return phase
        }
        return nil
    }

    var isRetry: Bool {
        if case .everyWordRetry = self {
            return true
        }
        return false
    }

    /// Whether this step counts toward the session score (and so the FSRS rating).
    var isScored: Bool {
        switch self {
        case .verbalRecite, .everyWord: true
        case .everyOtherWord, .everyWordRetry: false
        }
    }
}

/// What counts toward a session's score, overall and per verse. Only
/// ``ActivityStep/isScored`` steps contribute; every word counts as one.
nonisolated struct SessionTally {
    private(set) var correct = 0
    private(set) var total = 0
    /// Per-verse tallies, indexed like the session's verses.
    private(set) var verseCorrect: [Int]
    private(set) var verseTotal: [Int]
    /// Per-verse word positions missed in any scored step (see ``VerseWords``).
    private(set) var verseMissed: [Set<Int>]
    /// Word index (in the joined text) → index into the session's verses.
    private let wordOwners: [Int]
    /// Word index → the word's position within its verse, or `nil` for a
    /// token that isn't a word (a lone dash).
    private let wordPositions: [Int?]

    /// - Parameter wordPositions: when omitted, every token counts as a word
    ///   and is numbered within its verse.
    init(verseCount: Int = 0, wordOwners: [Int] = [], wordPositions: [Int?]? = nil) {
        verseCorrect = Array(repeating: 0, count: verseCount)
        verseTotal = Array(repeating: 0, count: verseCount)
        verseMissed = Array(repeating: [], count: verseCount)
        self.wordOwners = wordOwners
        if let wordPositions {
            self.wordPositions = wordPositions
        } else {
            var seen = Array(repeating: 0, count: verseCount)
            self.wordPositions = wordOwners.map { owner in
                defer { seen[owner] += 1 }
                return seen[owner]
            }
        }
    }

    /// Adds one finished step; unscored steps are ignored. Results are
    /// attributed to verses word by word.
    mutating func record(step: ActivityStep, correct: Int, total: Int, perWord: [Int: Bool]) {
        guard step.isScored else { return }
        self.correct += correct
        self.total += total

        for (wordIndex, isCorrect) in perWord {
            guard wordIndex < wordOwners.count else { continue }
            let verseIndex = wordOwners[wordIndex]
            verseTotal[verseIndex] += 1
            if isCorrect {
                verseCorrect[verseIndex] += 1
            } else if wordIndex < wordPositions.count, let position = wordPositions[wordIndex] {
                verseMissed[verseIndex].insert(position)
            }
        }
    }
}

/// One completed activity, collected during a session and persisted as a
/// ``PracticeActivity`` when the session finishes.
struct ActivityRecord {
    let type: String
    let phase: Int?
    let isRetry: Bool
    let correctCount: Int
    let totalCount: Int
    let startDate: Date
    let endDate: Date
}
