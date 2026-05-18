//
//  PassageStore.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 4/8/26.
//

import Observation
import SwiftUI

@Observable
final class PassageStore: Store {
    static let shared = PassageStore()

    private(set) var userPassages: [UserPassage] = []

    // Store protocol requirements
    var state: DataState = .idle
    var lastError: APIError?

    init() {}

    @MainActor
    func loadMyPassages() async {
        state = .loading
        clearError()

        do {
            let responses = try await APIService.shared.getMyPassages()
            userPassages = responses.map { $0.toDomain() }
            state = .success
            log.info("Loaded \(userPassages.count) user passages")
        } catch {
            handle(error: error)
        }
    }

    @MainActor
    func resetState() {
        state = .idle
        lastError = nil
    }
}
