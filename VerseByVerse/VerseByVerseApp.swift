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
        }
        await MainActor.run { statusText = "Logging in…" }
        // Present login over the splash if needed
        await MainActor.run { showLogin = true }
        // Do not mark ready yet; post-login tasks will continue after dismissal
//        try? await Task.sleep(nanoseconds: 3_000_000_000)
//        await MainActor.run { showLogin = false }
        while showLogin {
            try? await Task.sleep(nanoseconds: 200_000_000)
            log.debug("waiting...")
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
