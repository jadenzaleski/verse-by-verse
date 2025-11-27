//
//  VerseByVerseApp.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/22/25.
//

import SwiftUI

@main
struct VerseByVerseApp: App {

    @State private var isReady = false
    @State private var statusText = "Loading…"

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
        await MainActor.run { statusText = "Preparing…"
            for family in UIFont.familyNames {
                print("\(family)")
                for name in UIFont.fontNames(forFamilyName: family) {
                    print("  \(name)")
                }
            }
        }
        try? await Task.sleep(nanoseconds: 600_000_000)

        await MainActor.run { statusText = "Fetching data…" }
        try? await Task.sleep(nanoseconds: 900_000_000)

        await MainActor.run { statusText = "Configuring…" }
        try? await Task.sleep(nanoseconds: 900_000_000)

        await MainActor.run { statusText = "Almost there…" }
        try? await Task.sleep(nanoseconds: 900_000_000)
        await MainActor.run { statusText = "I am Done." }
    }
}
