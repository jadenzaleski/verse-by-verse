//
//  SessionPreviewView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/6/26.
//

import SwiftUI

/// The whole passage, read once before a session's first activity. The
/// session clock and progress only start when the user taps Start.
///
/// For material already practiced, the text starts hidden so the first scored
/// step tests real recall; the user can tap Show Text to peek.
struct SessionPreviewView: View {
    let translation: String
    let text: Text?
    /// Hide the text until asked (a review of something already learned).
    let hidesText: Bool
    let onStart: () -> Void

    @State private var showsText = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    HStack(spacing: AppSpacing.sm) {
                        Text("Review")
                            .font(.app(.caption, weight: .semibold))
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.xs)
                            .background(Color.appAccent.opacity(0.15), in: Capsule())
                            .foregroundStyle(Color.appAccent)
                        Spacer()
                        Text(translation)
                            .font(.app(.caption))
                            .foregroundStyle(.secondary)
                    }

                    if hidesText, !showsText {
                        recallPrompt
                    } else {
                        text
                    }
                }
                .padding(AppSpacing.xl)
                .padding(.top, AppSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button("Start", action: onStart)
                .buttonStyle(.primary)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.lg)
        }
    }

    private var recallPrompt: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Try to recall it first")
                .font(.app(.title3, weight: .semibold))
            Text("What you remember without looking is what gets scored.")
                .font(.app(.subheadline))
                .foregroundStyle(.secondary)
            Button("Show Text") {
                showsText = true
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    SessionPreviewView(
        translation: "KJV",
        text: Text("For God so loved the world, that he gave his only begotten Son.").font(.bible()),
        hidesText: false,
        onStart: {},
    )
    .environment(\.font, .app())
}

#Preview("Review, text hidden") {
    SessionPreviewView(
        translation: "KJV",
        text: Text("For God so loved the world, that he gave his only begotten Son.").font(.bible()),
        hidesText: true,
        onStart: {},
    )
    .environment(\.font, .app())
}
