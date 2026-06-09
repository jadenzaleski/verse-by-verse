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

    @MainActor
    func loadMyPracticeSessions() async {
        state = .loading
        clearError()
        do {
            let responses = try await APIService.shared.getMyPracticeSessions()
            sessions = responses.map { $0.toDomain() }
            state = .success
            log.info("Loaded \(sessions.count) practice sessions")
        } catch {
            handle(error: error)
        }
    }

    func sessions(forPassageId id: Int) -> [PracticeSession] {
        sessions.filter { $0.passageId == id }
    }
}
