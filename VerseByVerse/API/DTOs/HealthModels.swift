//
//  HealthModels.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

// https://app.quicktype.io

import Foundation

struct GetHealthResponse: Codable {
    /// "ok" or "degraded" (Redis down — API still serves, uncached).
    let status: String
    let redis: String
}
