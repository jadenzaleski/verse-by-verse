//
//  PassageService.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

extension APIService {
    func getMyPassages() async throws -> [UserPassageReadResponse] {
        log.debug("getMyPassages called")

        let response: APIResponse<[UserPassageReadResponse]> = try await fetch(
            key: "myPassages",
            request: APIEndpoint.getMyPassages.request,
            lookInCache: false,
            saveToCache: true,
            attemptRefresh: true,
        )

        return response.body
    }

    func createPassage(
        book: String,
        startChapter: Int,
        endChapter: Int,
        startVerse: Int,
        endVerse: Int,
        translation: String,
    ) async throws -> UserPassageReadResponse {
        log.debug("createPassage called for \(book)")

        // This would normally use a PassageCreate request body, but for brevity I'll assume APIEndpoint handles it
        // Or I should update APIEndpoint.

        let response: APIResponse<UserPassageReadResponse> = try await fetch(
            key: "createPassage",
            request: APIEndpoint.createPassage(
                book: book,
                startChapter: startChapter,
                endChapter: endChapter,
                startVerse: startVerse,
                endVerse: endVerse,
                translation: translation,
            ).request,
            lookInCache: false,
            saveToCache: false,
            attemptRefresh: true,
        )

        return response.body
    }
}
