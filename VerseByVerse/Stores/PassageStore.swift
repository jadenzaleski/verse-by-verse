//
//  PassageStore.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 4/8/26.
//

import Observation
import SwiftUI

@Observable
final class PassageStore {
    static let shared = PassageStore()

    private(set) var fetchedPassage: BiblePassageResponse?
    private(set) var state: DataState = .idle
    private(set) var lastError: APIError?

    private let log = AppLog.category("PassageStore")

    init() {}

    @MainActor
    func fetchPassage(
        translation: String,
        start: String,
        end: String? = nil,
        strip: Bool = true
    ) async {
        state = .loading
        lastError = nil

        do {
            let passage = try await APIService.shared.getBiblePassage(
                translation: translation,
                start: start,
                end: end,
                strip: strip
            )
            fetchedPassage = passage
            state = .success
            log.info("Passage fetched successfully: \(start)")
        } catch let apiError as APIError {
            self.lastError = apiError
            self.state = .error(apiError)
            log.error("Failed to fetch passage: \(apiError.localizedDescription)")
        } catch {
            let unknownError = APIError.unknown(underlying: error)
            lastError = unknownError
            state = .error(unknownError)
            log.error("Unknown error fetching passage: \(error.localizedDescription)")
        }
    }

    @MainActor
    func clearPassage() {
        fetchedPassage = nil
        state = .idle
        lastError = nil
    }
}
