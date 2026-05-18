//
//  BibleService.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

extension APIService {
    func getBibleBooks() async throws -> BibleBooksResponse {
        log.debug("getBibleBooks called")

        do {
            let response: APIResponse<BibleBooksResponse> = try await fetch(
                key: "bibleBooks",
                expiresIn: 15 * 24 * 60 * 60, // 15 days
                request: APIEndpoint.getBibleBooks.request,
                lookInCache: true,
                saveToCache: true,
            )

            log.debug("getBibleBooks succeeded")

            return response.body
        } catch let apiError as APIError {
            log.error("getBibleBooks failed, error: \(apiError.localizedDescription)")
            throw apiError
        } catch {
            log.error("getBibleBooks failed, unknown error: \(error.localizedDescription)")
            throw error
        }
    }

    func getBibleTranslations(lookInCache: Bool = true, saveToCache: Bool = true)
        async throws -> BibleTranslationsResponse
    {
        log.debug("getBibleTranslations called")

        do {
            let response: APIResponse<BibleTranslationsResponse> = try await fetch(
                key: "bibleTranslations",
                expiresIn: 15 * 24 * 60 * 60, // 15 days
                request: APIEndpoint.getBibleTranslations.request,
                lookInCache: lookInCache,
                saveToCache: saveToCache,
            )

            log.debug("getBibleTranslations succeeded")

            return response.body
        } catch let apiError as APIError {
            log.error("getBibleTranslations failed, error: \(apiError.localizedDescription)")
            throw apiError
        } catch {
            log.error("getBibleTranslations failed, unknown error: \(error.localizedDescription)")
            throw error
        }
    }

    func getBibleSelection(
        translation: String,
        start: String,
        end: String? = nil,
        strip: Bool = true,
        lookInCache: Bool = true,
        saveToCache: Bool = true,
    ) async throws -> BibleSelectionResponse {
        log.debug("getBibleSelection called for \(start) in \(translation)")

        do {
            let response: APIResponse<BibleSelectionResponse> = try await fetch(
                key: "passage-\(translation)-\(start)-\(end ?? "none")-\(strip)",
                expiresIn: 30 * 24 * 60 * 60, // 30 days
                request: APIEndpoint.getBibleSelection(
                    translation: translation,
                    startReference: start,
                    endReference: end,
                    strip: strip,
                ).request,
                lookInCache: lookInCache,
                saveToCache: saveToCache,
            )

            log.debug("getBibleSelection succeeded")

            return response.body
        } catch let apiError as APIError {
            log.error("getBibleSelection failed, error: \(apiError.localizedDescription)")
            throw apiError
        } catch {
            log.error("getBibleSelection failed, unknown error: \(error.localizedDescription)")
            throw error
        }
    }
}
