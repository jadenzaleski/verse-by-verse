//
//  UserModels.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

// https://app.quicktype.io

import Foundation

struct UserResponse: Codable {
    let id, email: String
    let isActive, isSuperuser, isVerified: Bool
    let firstName, lastName: String?
    let lastLogin, createdAt, modifiedAt: Date?
    let fsrsParams: [String: Double]?
    let desiredRetention: Double
    let passages: [UserPassageReadResponse]?
    let studySets: [StudySetReadResponse]?
    let practiceSessions: [PracticeSessionReadResponse]?

    enum CodingKeys: String, CodingKey {
        case id, email
        case isActive = "is_active"
        case isSuperuser = "is_superuser"
        case isVerified = "is_verified"
        case firstName = "first_name"
        case lastName = "last_name"
        case lastLogin = "last_login"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
        case fsrsParams = "fsrs_params"
        case desiredRetention = "desired_retention"
        case passages
        case studySets = "study_sets"
        case practiceSessions = "practice_sessions"
    }
}
