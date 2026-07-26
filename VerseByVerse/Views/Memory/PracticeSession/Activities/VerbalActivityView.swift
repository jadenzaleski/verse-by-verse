//
//  VerbalActivityView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/8/26.
//

import SwiftUI

struct VerbalActivityView: View {
    let reference: String
    let text: Text
    /// Called with (1, 1) if correct, (0, 1) if missed.
    let onContinue: (Int, Int) -> Void

    @State private var revealed = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    HStack(spacing: AppSpacing.sm) {
                        Text("Verbal Recite")
                            .font(.app(.caption, weight: .semibold))
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.xs)
                            .background(Color.appAccent.opacity(0.15), in: Capsule())
                            .foregroundStyle(Color.appAccent)
                        Spacer()
                        Text(reference)
                            .font(.app(.caption))
                            .foregroundStyle(.secondary)
                    }

                    if revealed {
                        text
                            .transition(.opacity)
                    } else {
                        VStack(spacing: AppSpacing.lg) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.appAccent)

                            Text("Say the verse aloud from memory.")
                                .font(.app(.title3, weight: .semibold))
                                .multilineTextAlignment(.center)

                            Text("Tap Reveal when you're ready to check yourself.")
                                .font(.app(.subheadline))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, AppSpacing.xxl)
                    }
                }
                .padding(AppSpacing.xl)
                .padding(.top, AppSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeIn(duration: 0.2), value: revealed)
            }

            VStack(spacing: AppSpacing.md) {
                if !revealed {
                    Button {
                        withAnimation { revealed = true }
                    } label: {
                        Text("Reveal")
                            .font(.app(.body, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppRadius.md)
                            .background(Color.appAccent, in: RoundedRectangle(cornerRadius: AppRadius.md))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: AppSpacing.md) {
                        Button { onContinue(0, 1) } label: {
                            Label("Missed it", systemImage: "xmark")
                                .font(.app(.body, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppRadius.md)
                                .background(
                                    Color.appDestructive.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: AppRadius.md),
                                )
                                .foregroundStyle(Color.appDestructive)
                        }
                        .buttonStyle(.plain)

                        Button { onContinue(1, 1) } label: {
                            Label("Got it", systemImage: "checkmark")
                                .font(.app(.body, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppRadius.md)
                                .background(Color.appSuccess, in: RoundedRectangle(cornerRadius: AppRadius.md))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }

                #if DEBUG
                    Button("Skip (debug — random score)") {
                        onContinue(Int.random(in: 0 ... 1), 1)
                    }
                    .font(.app(.caption))
                    .foregroundStyle(.tertiary)
                #endif
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, 30)
        }
    }
}

#Preview {
    VerbalActivityView(
        reference: "John 3:16",
        text: Text("""
        For God so loved the world that he gave his one and only \
        Son, that whoever believes in him shall not perish but have \
        eternal life.
        """).font(.bible(.body)),
        onContinue: { _, _ in },
    )
    .environment(\.font, .app())
}
