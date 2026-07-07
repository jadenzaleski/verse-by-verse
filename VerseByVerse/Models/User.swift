//
//  User.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

struct User: Identifiable, Equatable {
    let id: String
    let email: String
    let isActive: Bool
    let isSuperuser: Bool
    let isVerified: Bool
    let firstName: String?
    let lastName: String?
    let lastLogin: Date?
    let createdAt: Date?
    let modifiedAt: Date?

    let fsrsParams: [String: Double]?
    let desiredRetention: Double

    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        let full = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? "Anonymous" : full
    }
}

extension UserResponse {
    func toDomain() -> User {
        User(
            id: id,
            email: email,
            isActive: isActive,
            isSuperuser: isSuperuser,
            isVerified: isVerified,
            firstName: firstName,
            lastName: lastName,
            lastLogin: lastLogin,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            fsrsParams: fsrsParams,
            desiredRetention: desiredRetention,
        )
    }
}
