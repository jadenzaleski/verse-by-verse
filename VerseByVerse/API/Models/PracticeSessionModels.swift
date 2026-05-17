//
//  PracticeSessionModels.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/16/26.
//

// https://app.quicktype.io

import Foundation

struct PracticeSession: Identifiable, Equatable {
    let id: Int
    let date: Date
    let score: Double // actual score (0-1)
    let stability: Double // FSRS stability in days
}
