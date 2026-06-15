//
//  StudySetStore.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/24/26.
//

import Observation
import SwiftUI

@Observable
final class StudySetStore: Store {
    static let shared = StudySetStore()

    var state: DataState = .idle
    var lastError: APIError?

    private(set) var sets: [StudySet] = []

    private init() {}

    @MainActor
    func loadMySets(lookInCache: Bool = true) async {
        state = .loading
        clearError()

        do {
            let responses = try await APIService.shared.getMyStudySets()
            sets = responses.map { $0.toDomain() }
            state = .success
            log.info("Loaded \(sets.count) study sets")
        } catch {
            handle(error: error)
        }
    }

    @MainActor
    func createSet(name: String, description: String?, theme: MeshTheme) async throws {
        state = .loading
        clearError()

        do {
            let positionSeed = Int.random(in: 1 ... 99999)
            let colorSeed = Int.random(in: 1 ... 99999)
            let response = try await APIService.shared.createStudySet(
                name: name,
                description: description,
                positionSeed: positionSeed,
                colorSeed: colorSeed,
                theme: theme,
                passageIds: nil,
            )
            let newSet = response.toDomain()
            sets.append(newSet)
            state = .success
            log.info("Created study set: \(newSet.id)")
        } catch {
            handle(error: error)
            throw error
        }
    }
}
