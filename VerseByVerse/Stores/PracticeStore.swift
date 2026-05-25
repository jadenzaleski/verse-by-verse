//
//  PracticeStore.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/24/26.
//

import Observation
import SwiftUI

@Observable
final class PracticeStore: Store {
    static let shared = PracticeStore()

    var state: DataState = .idle
    var lastError: APIError?

    private(set) var sessions: [PracticeSession] = []

    private init() {}
}
