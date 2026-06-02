//
//  StudySetService.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

extension APIService {
    func getMyStudySets() async throws -> [StudySetReadResponse] {
        log.debug("getMyStudySets called")
        let response: APIResponse<[StudySetReadResponse]> = try await fetch(
            endpoint: APIEndpoint.getMyStudySets,
            lookInCache: false,
            saveToCache: true,
        )
        return response.body
    }

    func createStudySet(
        name: String,
        description: String?,
        positionSeed: Int,
        colorSeed: Int,
        theme: MeshTheme,
        passageIds: [Int]?,
    ) async throws -> StudySetReadResponse {
        log.debug("createStudySet called: \(name)")
        let response: APIResponse<StudySetReadResponse> = try await fetch(
            endpoint: APIEndpoint.createStudySet(
                name: name,
                description: description,
                positionSeed: positionSeed,
                colorSeed: colorSeed,
                theme: theme.rawValue,
                passageIds: passageIds,
            ),
            lookInCache: false,
            saveToCache: false,
        )
        return response.body
    }
}
