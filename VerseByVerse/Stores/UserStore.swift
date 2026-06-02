//
//  UserStore.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 2/24/26.
//

import Observation
import SwiftUI

@Observable
final class UserStore: Store {
    static let shared = UserStore()
    private(set) var currentUser: User?

    var state: DataState = .idle
    var lastError: APIError?

    private init() {
        NotificationCenter.default.addObserver(
            forName: .unauthorized,
            object: nil,
            queue: .main,
        ) { [weak self] _ in
            self?.logout()
        }
    }

    @MainActor
    func loadUser(lookInCache: Bool = true) async {
        state = .loading
        clearError()

        do {
            let userResponse = try await APIService.shared.getUser(lookInCache: lookInCache)
            currentUser = userResponse.toDomain()
            state = .success
            log.info("User loaded successfully: \(userResponse.id)")
        } catch {
            handle(error: error)
        }
    }

    @MainActor
    func patchUser(firstName: String? = nil,
                   lastName: String? = nil,
                   email: String? = nil,
                   password: String? = nil) async throws
    {
        state = .loading
        clearError()

        do {
            let updatedUserResponse = try await APIService.shared.patchUser(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password,
            )

            currentUser = updatedUserResponse.toDomain()
            state = .success

            log.info("User updated successfully")
        } catch {
            handle(error: error)
            throw error
        }
    }

    @MainActor
    func login(email: String, password: String) async throws {
        state = .loading
        clearError()

        do {
            let result = try await APIService.shared.postLogin(email: email, password: password)
            try KeychainManager.saveAccessToken(result.accessToken)
            try KeychainManager.saveRefreshToken(result.refreshToken)

            // Load the user data now that we have tokens
            let userResponse = try await APIService.shared.getUser(lookInCache: false)
            currentUser = userResponse.toDomain()
            state = .success
            log.info("Login successful for user: \(userResponse.id)")
        } catch {
            handle(error: error)
            throw error
        }
    }

    @MainActor
    func register(firstName: String, lastName: String, email: String, password: String) async throws {
        state = .loading
        clearError()

        do {
            _ = try await APIService.shared.postRegister(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password,
            )

            // Registration successful, now login to get tokens
            try await login(email: email, password: password)
            log.info("Registration and login successful")
        } catch {
            handle(error: error)
            throw error
        }
    }

    @MainActor
    func logout() {
        currentUser = nil
        resetStateAndError()

        // Clear tokens from Keychain
        try? KeychainManager.saveAccessToken("")
        try? KeychainManager.saveRefreshToken("")

        // Clear all cached data
        Cache.shared.removeAll()

        log.info("User signed out and data cleared")
    }

    /// Used by Login/Register to set the user once tokens are obtained
    @MainActor
    func setUser(_ user: UserResponse) {
        currentUser = user.toDomain()
        state = .success
    }
}
