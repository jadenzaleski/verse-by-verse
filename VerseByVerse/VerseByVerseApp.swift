//
//  VerseByVerseApp.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/22/25.
//

import SwiftUI
import UIKit

@main
struct VerseByVerseApp: App {
    @State private var isReady = false
    @State private var statusText = "Loading…"
    @State private var showLogin = false
    @State private var userStore = UserStore.shared
    private let log = AppLog.category("Init")
    private let cache = Cache.shared

    init() {
        log.info("--- Verse By Verse \(AppFunctions.versionString() ?? "") ---")
        log.log("Log level: \(AppLog.minimumLevel)")
        let backImage = UIImage(named: "lucide.chevron.left")
        UINavigationBar.appearance().backIndicatorImage = backImage
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backImage
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isReady {
                    ContentView()
                        .transition(.opacity)
                } else {
                    SplashView(statusText: $statusText, isDone: $isReady) {
                        await runStartup()
                    }
                    .transition(.opacity)
                }
            }
            .fullScreenCover(isPresented: $showLogin) {
                LoginOrRegisterView(showLogin: $showLogin)
            }
            .onChange(of: userStore.currentUser != nil) { wasLoggedIn, isLoggedIn in
                // If the user was logged in (wasLoggedIn == true) and is now logged out (isLoggedIn == false)
                // and the app is past the initial splash phase (isReady == true)
                log.debug("userStore.currentUser change detected: wasLoggedIn: \(wasLoggedIn) isLoggedIn: \(isLoggedIn) isReady: \(isReady)")
                if wasLoggedIn && !isLoggedIn && isReady {
                    withAnimation {
                        showLogin = true
                    }
                }
            }
            .animation(.easeOut(duration: 0.35), value: isReady)
            .environment(\.font, .app())
            .environment(userStore)
        }
    }

    private func runStartup() async {
        await MainActor.run {
            statusText = "Preparing…"
            log.info("Cache URL: \(cache.cacheDirectory)")
            if AppLog.minimumLevel == .debug {
                KeychainManager.debugDump()
                // dump AppStorage/UserDefaults
                log.debug("App UserDefaults:")
                let appDomain = Bundle.main.bundleIdentifier!
                if let mySettings = UserDefaults.standard.persistentDomain(forName: appDomain) {
                    log.debug("\(mySettings)")
                }
            }
        }
        // Present login over the splash if needed
        await MainActor.run {
            statusText = "Logging in…"
        }

        let hasAccessToken = (try? KeychainManager.getAccessToken()) != nil
        let hasRefreshToken = (try? KeychainManager.getRefreshToken()) != nil
        if hasAccessToken && hasRefreshToken {
            log.debug("There is a access token and refresh token, so we can attempt to load the user.")
            await userStore.loadUser(lookInCache: false)
        }

        await MainActor.run {
            let userLoaded = userStore.currentUser != nil
            log.debug("setting showLogin to: " + (!userLoaded ? "true" : "false"))
            showLogin = !userLoaded
            if showLogin {
                userStore.resetState()
            }
        }

        while await MainActor.run(body: { showLogin }) {
            try? await Task.sleep(nanoseconds: 250_000_000)
        }

//        await MainActor.run { statusText = "Configuring…" }
//        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Fade into main content
        await MainActor.run {
            withAnimation(.easeInOut) {
                isReady = true
            }
        }
    }
}

