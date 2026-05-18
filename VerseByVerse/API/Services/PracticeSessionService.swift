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
            key: "myPracticeSessions",
            request: APIEndpoint.getMyPracticeSessions.request,
            lookInCache: false,
            saveToCache: true,
            attemptRefresh: true,
        )
        return response.body
    }

    func startPracticeSession(passageId: Int) async throws -> PracticeSessionReadResponse {
        log.debug("startPracticeSession called for passage: \(passageId)")
        let response: APIResponse<PracticeSessionReadResponse> = try await fetch(
            key: "startPracticeSession",
            request: APIEndpoint.startPracticeSession(passageId: passageId).request,
            lookInCache: false,
            saveToCache: false,
            attemptRefresh: true,
        )
        return response.body
    }

    func completePracticeSession(id: Int, score: Double) async throws -> PracticeSessionReadResponse {
        log.debug("completePracticeSession called for session: \(id)")
        let response: APIResponse<PracticeSessionReadResponse> = try await fetch(
            key: "completePracticeSession",
            request: APIEndpoint.completePracticeSession(id: id, score: score).request,
            lookInCache: false,
            saveToCache: false,
            attemptRefresh: true,
        )
        return response.body
    }
}
