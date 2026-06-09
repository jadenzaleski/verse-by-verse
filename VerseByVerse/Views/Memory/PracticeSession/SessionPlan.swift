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
        case "Every Other Word": return .everyOtherWord(phase: step.phase ?? 0)
        case "Every Word":       return .everyWord(allowsRetry: step.allowsRetry)
        case "Verbal Recite":    return .verbalRecite
        default:                 return nil
        }
    }

    var activityType: String {
        switch self {
        case .everyOtherWord:        return "Every Other Word"
        case .everyWord, .everyWordRetry: return "Every Word"
        case .verbalRecite:          return "Verbal Recite"
        }
    }

    var phase: Int? {
        if case .everyOtherWord(let phase) = self { return phase }
        return nil
    }

    var isRetry: Bool {
        if case .everyWordRetry = self { return true }
        return false
    }
}
