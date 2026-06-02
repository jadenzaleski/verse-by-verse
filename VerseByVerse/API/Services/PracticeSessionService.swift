//
//  PracticeSessionService.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

extension APIService {
    func getMyPracticeSessions() async throws -> [PracticeSessionReadResponse] {
        log.debug("getMyPracticeSessions called")
        let response: APIResponse<[PracticeSessionReadResponse]> = try await fetch(
            endpoint: APIEndpoint.getMyPracticeSessions,
            lookInCache: false,
            saveToCache: true,
        )
        return response.body
    }

    func startPracticeSession(passageId: Int) async throws -> PracticeSessionReadResponse {
        log.debug("startPracticeSession called for passage: \(passageId)")
        let response: APIResponse<PracticeSessionReadResponse> = try await fetch(
            endpoint: APIEndpoint.startPracticeSession(passageId: passageId),
            lookInCache: false,
            saveToCache: false,
        )
        return response.body
    }

    func completePracticeSession(id: Int, score: Double) async throws -> PracticeSessionReadResponse {
        log.debug("completePracticeSession called for session: \(id)")
        let response: APIResponse<PracticeSessionReadResponse> = try await fetch(
            endpoint: APIEndpoint.completePracticeSession(id: id, score: score),
            lookInCache: false,
            saveToCache: false,
        )
        return response.body
    }
}
