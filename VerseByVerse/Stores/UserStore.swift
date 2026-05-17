//
//  UserStore.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 2/24/26.
//

import Observation
import SwiftUI

enum DataState: Equatable {
    case idle
    case loading
    case success
    case error(APIError)

    static func == (lhs: DataState, rhs: DataState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.success, .success):
            true
        case (.error, .error):
            // Consider all error states equal regardless of underlying APIError
            true
        default:
            false
        }
    }
}

@Observable
final class UserStore {
    static let shared = UserStore()
    // Anyone can read this property, but only this class can change it.
    // This is important when maintaining a single source of truth.
    private(set) var currentUser: UserResponse?
    private(set) var state: DataState = .idle
    private(set) var lastError: APIError?

    private let log = AppLog.category("UserStore")

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
        lastError = nil

        do {
            let user = try await APIService.shared.getUser(lookInCache: lookInCache)
            currentUser = user
            state = .success
            log.info("User loaded successfully: \(user.id)")
        } catch let apiError as APIError {
            // If it's 401 or 400, the unauthorized notification was likely fired
            // or the session is just invalid. Don't show an error alert for these.
            if apiError.statusCode == 401 || apiError.statusCode == 400 {
                state = .idle
                return
            }
            self.lastError = apiError
            self.state = .error(apiError)
            log.error("Failed to load user: \(apiError.localizedDescription)")
        } catch {
            let unknownError = APIError.unknown(underlying: error)
            lastError = unknownError
            state = .error(unknownError)
            log.error("Unknown error loading user: \(error.localizedDescription)")
        }
    }

    @MainActor
    func patchUser(firstName: String? = nil,
                   lastName: String? = nil,
                   email: String? = nil,
                   password: String? = nil) async throws
    {
        state = .loading
        lastError = nil

        do {
            let updatedUser = try await APIService.shared.patchUser(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password,
            )

            currentUser = updatedUser
            state = .success

            // Invalidate the cache for getUser to ensure consistency
            Cache.shared.remove("getUser")
            log.info("User updated successfully")
        } catch let apiError as APIError {
            // If it's 401 or 400, the unauthorized notification was likely fired
            // or the session is just invalid. Don't show an error alert for these.
            if apiError.statusCode == 401 || apiError.statusCode == 400 {
                state = .idle
                throw apiError
            }
            self.lastError = apiError
            self.state = .error(apiError)
            log.error("Failed to patch user: \(apiError.localizedDescription)")
            throw apiError
        } catch {
            let unknownError = APIError.unknown(underlying: error)
            lastError = unknownError
            state = .error(unknownError)
            log.error("Unknown error patching user: \(error.localizedDescription)")
            throw unknownError
        }
    }

    @MainActor
    func login(email: String, password: String) async throws {
        state = .loading
        lastError = nil

        do {
            let result = try await APIService.shared.postLogin(email: email, password: password)
            try KeychainManager.saveAccessToken(result.accessToken)
            try KeychainManager.saveRefreshToken(result.refreshToken)

            // Load the user data now that we have tokens
            let user = try await APIService.shared.getUser(lookInCache: false)
            currentUser = user
            state = .success
            log.info("Login successful for user: \(user.id)")
        } catch let apiError as APIError {
            self.lastError = apiError
            self.state = .error(apiError)
            log.error("Login failed: \(apiError.localizedDescription)")
            throw apiError
        } catch {
            let unknownError = APIError.unknown(underlying: error)
            lastError = unknownError
            state = .error(unknownError)
            log.error("Unknown error during login: \(error.localizedDescription)")
            throw unknownError
        }
    }

    @MainActor
    func register(firstName: String, lastName: String, email: String, password: String) async throws {
        state = .loading
        lastError = nil

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
        } catch let apiError as APIError {
            self.lastError = apiError
            self.state = .error(apiError)
            log.error("Registration failed: \(apiError.localizedDescription)")
            throw apiError
        } catch {
            let unknownError = APIError.unknown(underlying: error)
            lastError = unknownError
            state = .error(unknownError)
            log.error("Unknown error during registration: \(error.localizedDescription)")
            throw unknownError
        }
    }

    @MainActor
    func resetState() {
        state = .idle
        lastError = nil
    }

    @MainActor
    func logout() {
        currentUser = nil
        state = .idle
        lastError = nil

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
        currentUser = user
        state = .success
    }

    func clearError() {
        lastError = nil
    }
}
