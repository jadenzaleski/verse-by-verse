//
//  HealthModels.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

// https://app.quicktype.io

import Foundation

struct GetHealthResponse: Codable {
    let status: String
    // swiftlint:disable:next identifier_name
    let db: String
    let redis: String
}
