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

    func updateStudySet(
        id: Int,
        name: String?,
        description: String?,
        theme: MeshTheme?,
    ) async throws -> StudySetReadResponse {
        log.debug("updateStudySet called: \(id)")
        let response: APIResponse<StudySetReadResponse> = try await fetch(
            endpoint: APIEndpoint.patchStudySet(
                id: id,
                name: name,
                description: description,
                positionSeed: nil,
                colorSeed: nil,
                theme: theme?.rawValue,
            ),
            lookInCache: false,
            saveToCache: false,
        )
        return response.body
    }

    func getStudySet(id: Int) async throws -> StudySetDetailResponse {
        log.debug("getStudySet called: \(id)")
        let response: APIResponse<StudySetDetailResponse> = try await fetch(
            endpoint: APIEndpoint.getStudySet(id: id),
            lookInCache: false,
            saveToCache: false,
        )
        return response.body
    }

    func deleteStudySet(id: Int) async throws {
        log.debug("deleteStudySet called: \(id)")
        try await fetchVoid(endpoint: APIEndpoint.deleteStudySet(id: id))
    }

    func addPassageToStudySet(studySetId: Int, passageId: Int) async throws -> StudySetDetailResponse {
        log.debug("addPassageToStudySet called: set \(studySetId), passage \(passageId)")
        let response: APIResponse<StudySetDetailResponse> = try await fetch(
            endpoint: APIEndpoint.addPassageToStudySet(studySetId: studySetId, passageId: passageId),
            lookInCache: false,
            saveToCache: false,
        )
        return response.body
    }

    func removePassageFromStudySet(studySetId: Int, passageId: Int) async throws -> StudySetDetailResponse {
        log.debug("removePassageFromStudySet called: set \(studySetId), passage \(passageId)")
        let response: APIResponse<StudySetDetailResponse> = try await fetch(
            endpoint: APIEndpoint.removePassageFromStudySet(studySetId: studySetId, passageId: passageId),
            lookInCache: false,
            saveToCache: false,
        )
        return response.body
    }
}
