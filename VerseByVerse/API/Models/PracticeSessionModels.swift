//
//  PracticeSessionModels.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/16/26.
//

import Foundation

struct PracticeSessionReadResponse: Codable {
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
    let createdAt: Date
    let modifiedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, score, rating, state
        case userId = "user_id"
        case passageId = "passage_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case scheduledDays = "scheduled_days"
        case elapsedDays = "elapsed_days"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
    }
}

struct CompletePracticeSessionResponse: Codable {
    let sessionId: Int
    let rating: Int
    let nextReview: Date?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case rating
        case nextReview = "next_review"
    }
}
