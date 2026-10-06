//
//  SessionPreviewView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/6/26.
//

import SwiftUI

/// The whole passage, read once before a session's first activity. The
/// session clock and progress only start when the user taps Start.
struct SessionPreviewView: View {
    let translation: String
    let text: Text?
    let onStart: () -> Void

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

                    text
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
}

#Preview {
    SessionPreviewView(
        translation: "KJV",
        text: Text("For God so loved the world, that he gave his only begotten Son.").font(.bible()),
        onStart: {},
    )
    .environment(\.font, .app())
}
