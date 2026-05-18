//
//  UserService.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

extension APIService {
    func getUser(lookInCache: Bool = true, saveToCache: Bool = true) async throws -> UserResponse {
        log.debug("getUser called")

        do {
            let response: APIResponse<UserResponse> = try await fetch(
                key: "getUser",
                expiresIn: 15 * 60,
                request: APIEndpoint.getUser.request,
                lookInCache: lookInCache,
                saveToCache: saveToCache,
                attemptRefresh: true,
            )

            log.debug(
                "getUser succeeded — statusCode: \(response.statusCode), id: \(response.body.id)",
            )

            return response.body
        } catch let apiError as APIError {
            let code = apiError.statusCode.map(String.init) ?? "n/a"
            log.error("getUser failed, statusCode: \(code), " +
                "error: \(apiError.localizedDescription)")
            throw apiError
        } catch {
            log.error("getUser failed, unknown error: \(error.localizedDescription)")
            throw error
        }
    }

    func patchUser(firstName: String? = nil,
                   lastName: String? = nil,
                   email: String? = nil,
                   password: String? = nil) async throws -> UserResponse
    {
        log.debug("patchUser called")

        do {
            let response: APIResponse<UserResponse> = try await fetch(
                key: "patchUser",
                request: APIEndpoint.patchUser(
                    firstName: firstName, lastName: lastName, email: email, password: password,
                ).request,
                lookInCache: false,
                saveToCache: false,
                attemptRefresh: true,
            )

            log.debug(
                "patchUser succeeded — statusCode: \(response.statusCode), id: \(response.body.id)",
            )

            return response.body
        } catch let apiError as APIError {
            let code = apiError.statusCode.map(String.init) ?? "n/a"
            log.error("patchUser failed, statusCode: \(code), " +
                "error: \(apiError.localizedDescription)")
            throw apiError
        } catch {
            log.error("patchUser failed, unknown error: \(error.localizedDescription)")
            throw error
        }
    }
}
