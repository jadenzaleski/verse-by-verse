//
//  PracticeSession.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/16/26.
//

import Foundation

struct PracticeSession: Identifiable, Equatable {
    let id: Int
    let userId: String
    let passageId: Int?
    let startDate: Date
    let endDate: Date?
    let score: Double?
    let rating: Int?
    let scheduledDays: Int?
    let elapsedDays: Int?
    let state: Int?

    var isCompleted: Bool {
        endDate != nil
    }
}

extension PracticeSessionReadResponse {
    func toDomain() -> PracticeSession {
        PracticeSession(
            id: id,
            userId: userId,
            passageId: passageId,
            startDate: startDate,
            endDate: endDate,
            score: score,
            rating: rating,
            scheduledDays: scheduledDays,
            elapsedDays: elapsedDays,
            state: state,
        )
    }
}
