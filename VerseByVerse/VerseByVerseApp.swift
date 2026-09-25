//
//  VerseByVerseApp.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/22/25.
//

import SwiftData
import SwiftUI
import UIKit

@main
struct VerseByVerseApp: App {
    @State private var isReady = false
    @State private var statusText = "Loading…"
    @State private var showCorruptStoreAlert = false
    private let container = AppModelContainer.make()
    private let bibleStore = BibleStore.shared
    private let networkMonitor = NetworkMonitor.shared
    private let log = AppLog.category("Init")

    init() {
        log.info("--- Verse By Verse \(AppFunctions.versionString() ?? "") ---")
        log.log("Log level: \(AppLog.minimumLevel)")
        let backImage = UIImage(systemName: "chevron.left")
        UINavigationBar.appearance().backIndicatorImage = backImage
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backImage
        showCorruptStoreAlert = AppModelContainer.didRecoverFromCorruptStore
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
            .environment(bibleStore)
            .environment(networkMonitor)
            .alert("Local Data Reset", isPresented: $showCorruptStoreAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your local data couldn't be read and had to be reset.")
            }
        }
        .modelContainer(container)
    }

    /// Warms the Bible metadata caches and takes the network monitor's first
    /// reading. The app is local-first: failures here are non-fatal (verse
    /// text simply loads on demand later, and the Home network widget picks
    /// up an offline/unreachable state), so startup is bounded by the
    /// network client's 15s timeout in the worst case.
    private func runStartup() async {
        await MainActor.run { statusText = "Fetching Bible data…" }
        async let books: Void = bibleStore.loadBibleData()
        async let translations: Void = bibleStore.loadTranslations()
        async let network: Void = networkMonitor.start()
        _ = await (books, translations, network)
        await MainActor.run { statusText = "Launching…" }
    }
}
