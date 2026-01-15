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
                }
            }
            .animation(.easeOut(duration: 0.35), value: isReady)
            .environment(\.font, .app())
        }
    }

    private func runStartup() async {
        await MainActor.run {
            statusText = "Preparing…"
            log.info("Cache URL: \(cache.cacheDirectory)")
//            for family in UIFont.familyNames {
//                print("\(family)")
//                for name in UIFont.fontNames(forFamilyName: family) {
//                    print("  \(name)")
//                }
//            }
        }
        try? await Task.sleep(nanoseconds: 200_000_000)

        await MainActor.run { statusText = "Fetching data…" }
        try? await Task.sleep(nanoseconds: 200_000_000)

        await MainActor.run { statusText = "Configuring…" }
        try? await Task.sleep(nanoseconds: 200_000_000)

        await MainActor.run { statusText = "Almost there…" }
        try? await Task.sleep(nanoseconds: 200_000_000)
    }
}
