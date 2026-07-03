//
//  VerbalActivityView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/8/26.
//

import SwiftUI

struct VerbalActivityView: View {
    let passage: UserPassage
    let verseText: String
    /// Called with (1, 1) if correct, (0, 1) if missed.
    let onContinue: (Int, Int) -> Void

    @State private var revealed = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 8) {
                        Text("Verbal Recite")
                            .font(.app(.caption, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                        Text(passage.reference)
                            .font(.app(.caption))
                            .foregroundStyle(.secondary)
                    }

                    if revealed {
                        Text(verseText)
                            .font(.app(.body))
                            .transition(.opacity)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.accentColor)

                            Text("Say the verse aloud from memory.")
                                .font(.app(.title3, weight: .semibold))
                                .multilineTextAlignment(.center)

                            Text("Tap Reveal when you're ready to check yourself.")
                                .font(.app(.subheadline))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                    }
                }
                .padding(20)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeIn(duration: 0.2), value: revealed)
            }

            VStack(spacing: 12) {
                if !revealed {
                    Button {
                        withAnimation { revealed = true }
                    } label: {
                        Text("Reveal")
                            .font(.app(.body, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 12) {
                        Button { onContinue(0, 1) } label: {
                            Label("Missed it", systemImage: "xmark")
                                .font(.app(.body, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)

                        Button { onContinue(1, 1) } label: {
                            Label("Got it", systemImage: "checkmark")
                                .font(.app(.body, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.green, in: RoundedRectangle(cornerRadius: 14))
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
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
    }
}

#Preview {
    let passage = UserPassage(
        id: 1, userId: "test", book: "John",
        startChapter: 3, endChapter: 3, startVerse: 16, endVerse: 16,
        translation: "KJV",
        lastPracticed: nil, nextPractice: nil,
        stability: 1.0, difficulty: 5.0, state: 0,
        reps: 0, lapses: 0, scheduledDays: 0, elapsedDays: 0,
    )
    VerbalActivityView(
        passage: passage,
        verseText: """
        For God so loved the world that he gave his one and only 
        Son, that whoever believes in him shall not perish but have 
        eternal life.
        """,
        onContinue: { _, _ in },
    )
    .environment(\.font, .app())
}
