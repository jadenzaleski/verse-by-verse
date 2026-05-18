//
//  UserPassageModels.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

struct UserPassageReadResponse: Codable {
    let id: Int
    let userId: String
    let book: String
    let startChapter: Int
    let endChapter: Int
    let startVerse: Int
    let endVerse: Int
    let translation: String
    let lastPracticed: Date?
    let nextPractice: Date?
    let stability: Double
    let difficulty: Double
    let state: Int
    let reps: Int
    let lapses: Int
    let scheduledDays: Int
    let elapsedDays: Int
    let createdAt: Date
    let modifiedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, book, translation, stability, difficulty, state, reps, lapses
        case userId = "user_id"
        case startChapter = "start_chapter"
        case endChapter = "end_chapter"
        case startVerse = "start_verse"
        case endVerse = "end_verse"
        case lastPracticed = "last_practiced"
        case nextPractice = "next_practice"
        case scheduledDays = "scheduled_days"
        case elapsedDays = "elapsed_days"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
    }
}
