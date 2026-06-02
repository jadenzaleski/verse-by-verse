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
            endpoint: APIEndpoint.getMyPassages,
            lookInCache: false,
            saveToCache: true,
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

        let response: APIResponse<UserPassageReadResponse> = try await fetch(
            endpoint: APIEndpoint.createPassage(
                book: book,
                startChapter: startChapter,
                endChapter: endChapter,
                startVerse: startVerse,
                endVerse: endVerse,
                translation: translation,
            ),
            lookInCache: false,
            saveToCache: false,
        )

        return response.body
    }
}
