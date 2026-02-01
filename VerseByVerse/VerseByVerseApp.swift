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
//    @State private var readyForMain = false
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
                    .fullScreenCover(isPresented: $showLogin) {
                        LoginOrRegisterView(showLogin: $showLogin)
                    }
                }
            }
//            .animation(.easeOut(duration: 0.35), value: readyForMain)
            .animation(.easeOut(duration: 0.35), value: isReady)
            .environment(\.font, .app())
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
        do {
            await MainActor.run {
                statusText = "Logging in…"
            }
            // Perform potentially throwing work off the main actor if needed
            let api = APIService()
            let user = try await api.getUser()
            await MainActor.run {
                log.debug("setting showLogin to:" + (user.id.isEmpty ? "true" : "false"))
                // Present login if no cached/authenticated user
                showLogin = (user.id.isEmpty)
            }
        } catch {
            // If fetching user fails, show login
            await MainActor.run {
                showLogin = true
                statusText = "Login required"
            }
        }

        while await MainActor.run(body: { showLogin }) {
            try? await Task.sleep(nanoseconds: 250_000_000)
        }

        await MainActor.run { statusText = "Configuring…" }
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        await MainActor.run { statusText = "Almost there…" }
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Fade into main content
        await MainActor.run {
            withAnimation(.easeInOut) {
                isReady = true
            }
        }
    }
}
