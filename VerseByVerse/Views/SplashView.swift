//
//  SplashView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/22/25.
//

import os
import SwiftUI

struct SplashView: View {
    @Binding var statusText: String
    @Binding var isDone: Bool
    let startupTasks: () async -> Void
    @State private var playOn = true
    @State private var playOff = false
    private let log = AppLog.category("Init")

    var body: some View {
        ZStack {
            VStack {
                Image("lucide.book.open.text")
                    .font(.system(size: 80))
                    .symbolEffect(.drawOn.byLayer, options: .nonRepeating.speed(0.5), isActive: playOn)
                    .symbolEffect(.drawOff.byLayer.reversed, options: .nonRepeating.speed(1.3), isActive: playOff)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("CustomPurple"), Color("CustomGreen")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing,
                        ),
                    )
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 2, y: 2)
            }
            .zIndex(1)
            .onAppear {
                Task {
                    // Allow a tiny delay before playing the draw-on
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    playOn = false // stop draw-on
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    // Now that the logo has drawn, continue on
                    log.info("Running startupTasks")
                    await startupTasks()
                    log.debug("startupTasks finished, playing drawOff")
                    playOff = true
                    // Wait long enough for drawOff animation to finish
                    try? await Task.sleep(nanoseconds: 400_000_000)

                    isDone = true
                }
            }

            VStack {
                Spacer()
                ProgressView()
                Text(statusText)
                Text(AppFunctions.versionString() ?? "")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SplashView(statusText: .constant("Loading…"), isDone: .constant(true)) {}
        .environment(\.font, .app())
}
