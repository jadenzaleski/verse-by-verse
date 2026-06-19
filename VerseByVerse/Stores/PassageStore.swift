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
    func loadMyPassages(lookInCache: Bool = true) async {
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
    func createPassage(
        book: String,
        startChapter: Int,
        endChapter: Int,
        startVerse: Int,
        endVerse: Int,
        translation: String
    ) async throws {
        state = .loading
        clearError()

        do {
            let response = try await APIService.shared.createPassage(
                book: book,
                startChapter: startChapter,
                endChapter: endChapter,
                startVerse: startVerse,
                endVerse: endVerse,
                translation: translation
            )
            
            let newPassage = response.toDomain()
            userPassages.append(newPassage)
            state = .success
            log.info("Created new passage: \(newPassage.id)")
        } catch {
            handle(error: error)
            throw error
        }
    }

    @MainActor
    func resetState() {
        state = .idle
        lastError = nil
    }
}

#if DEBUG
extension PassageStore {
    @MainActor
    func setUserPassagesForPreview(_ passages: [UserPassage]) {
        self.userPassages = passages
    }
}
#endif
