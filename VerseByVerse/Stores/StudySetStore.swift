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

    #if DEBUG
    @MainActor
    func setSetsForPreview(_ sets: [StudySet]) {
        self.sets = sets
    }
    #endif

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

    @MainActor
    func updateSet(id: Int, name: String, description: String?, theme: MeshTheme) async throws -> StudySet {
        state = .loading
        clearError()

        do {
            let response = try await APIService.shared.updateStudySet(
                id: id,
                name: name,
                description: description,
                theme: theme,
            )
            let updated = response.toDomain()
            if let idx = sets.firstIndex(where: { $0.id == id }) {
                sets[idx] = updated
            }
            state = .success
            log.info("Updated study set: \(id)")
            return updated
        } catch {
            handle(error: error)
            throw error
        }
    }

    @MainActor
    func deleteSet(id: Int) async throws {
        state = .loading
        clearError()

        do {
            try await APIService.shared.deleteStudySet(id: id)
            sets.removeAll { $0.id == id }
            state = .success
            log.info("Deleted study set: \(id)")
        } catch {
            handle(error: error)
            throw error
        }
    }
}
