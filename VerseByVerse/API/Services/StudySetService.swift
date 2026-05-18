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
            key: "myStudySets",
            request: APIEndpoint.getMyStudySets.request,
            lookInCache: false,
            saveToCache: true,
            attemptRefresh: true,
        )
        return response.body
    }

    func createStudySet(name: String, description: String?, positionSeed: Int, colorSeed: Int, theme: MeshTheme, passageIds: [Int]?) async throws -> StudySetReadResponse {
        log.debug("createStudySet called: \(name)")
        let response: APIResponse<StudySetReadResponse> = try await fetch(
            key: "createStudySet",
            request: APIEndpoint.createStudySet(
                name: name,
                description: description,
                positionSeed: positionSeed,
                colorSeed: colorSeed,
                theme: theme.rawValue,
                passageIds: passageIds,
            ).request,
            lookInCache: false,
            saveToCache: false,
            attemptRefresh: true,
        )
        return response.body
    }
}
