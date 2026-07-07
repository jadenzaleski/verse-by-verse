//
//  SessionPlan.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/8/26.
//

import Foundation

enum ActivityStep: Equatable {
    case everyOtherWord(phase: Int)
    case everyWord(allowsRetry: Bool)
    case everyWordRetry
    case verbalRecite
}

extension ActivityStep {
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

    var phase: Int? {
        if case let .everyOtherWord(phase) = self { return phase }
        return nil
    }

    var isRetry: Bool {
        if case .everyWordRetry = self { return true }
        return false
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
