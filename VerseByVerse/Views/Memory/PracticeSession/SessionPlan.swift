//
//  SessionPlan.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/8/26.
//

enum ActivityStep: Equatable {
    case everyOtherWord(phase: Int)
    case everyWord(allowsRetry: Bool)
    case everyWordRetry
    case verbalRecite
}

extension ActivityStep {
    static func from(_ step: PlanStep) -> ActivityStep? {
        switch step.type {
        case "Every Other Word": .everyOtherWord(phase: step.phase ?? 0)
        case "Every Word": .everyWord(allowsRetry: step.allowsRetry)
        case "Verbal Recite": .verbalRecite
        default: nil
        }
    }

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
