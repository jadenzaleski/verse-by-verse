//
//  ActivityView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/8/26.
//

import SwiftUI

/// A masked-word typing activity (Every Other Word / Every Word). Typing
/// correctness is derived by `TypingProgress`; this view is just layout and
/// the hidden `TextField` that captures keystrokes.
struct ActivityView: View {
    let activityName: String
    let reference: String
    let passageText: String
    /// Ordered word indices the user must type the first letter of.
    let maskedIndices: [Int]
    let instruction: String
    /// Called with (correct, total, per-word correctness keyed by word index)
    /// when the user taps Continue.
    let onContinue: (Int, Int, [Int: Bool]) -> Void

    /// The letters the user has committed so far, one per masked word. This is
    /// the answer: scoring and the word boxes read from it, and it only grows.
    @State private var typedLetters = ""
    /// The hidden text field's raw contents. It's a keystroke sensor, not the
    /// answer — backspace shrinks it, and only its growth is copied into
    /// `typedLetters` (see `TypingProgress.appending`).
    @State private var keyboardText = ""
    @FocusState private var fieldFocused: Bool

    private var progress: TypingProgress {
        TypingProgress(passageText: passageText, maskedIndices: maskedIndices, inputText: typedLetters)
    }

    /// Passage word index of the word currently being typed (the last masked
    /// word once everything is typed).
    private var currentWordIndex: Int? {
        let idx = progress.currentTypingIndex
        return idx < maskedIndices.count ? maskedIndices[idx] : maskedIndices.last
    }

    private var scoreColor: Color {
        let pct = progress.totalToType > 0 ? Double(progress.correctCount) / Double(progress.totalToType) : 0
        if pct >= 0.8 { return .green }
        if pct >= 0.5 { return .orange }
        return .red
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {
                        HStack(spacing: AppSpacing.sm) {
                            Text(activityName)
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

                        Text(instruction)
                            .font(.app(.subheadline))
                            .foregroundStyle(.secondary)

                        FlowLayout(spacing: 6, lineSpacing: 10) {
                            ForEach(Array(progress.words.enumerated()), id: \.offset) { idx, word in
                                wordCell(wordIndex: idx, word: word)
                                    .id(idx)
                            }
                        }
                    }
                    .padding(AppSpacing.xl)
                    .padding(.top, AppSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onTapGesture { fieldFocused = true }
                // Keep the word being typed in view as the user works down the passage.
                .onChange(of: progress.currentTypingIndex) {
                    guard let wordIndex = currentWordIndex else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(wordIndex, anchor: .center)
                    }
                }
            }

            // Hidden field that captures keystrokes
            TextField("", text: $keyboardText)
                .opacity(0)
                .frame(height: 1)
                .focused($fieldFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .onChange(of: keyboardText) { old, new in
                    typedLetters = TypingProgress.appending(
                        fieldChangeFrom: old, to: new, onto: typedLetters, limit: progress.totalToType,
                    )
                }

            VStack(spacing: AppSpacing.md) {
                if progress.isComplete {
                    HStack(spacing: AppSpacing.xs) {
                        Text("\(progress.correctCount) of \(progress.totalToType)")
                            .font(.app(.body, weight: .semibold))
                            .foregroundStyle(scoreColor)
                        Text("correct")
                            .font(.app(.body))
                            .foregroundStyle(.secondary)
                    }

                    Button("Continue") {
                        onContinue(progress.correctCount, progress.totalToType, progress.perWordCorrectness)
                    }
                    .buttonStyle(.primary)
                } else {
                    HStack {
                        Text("\(progress.currentTypingIndex) of \(progress.totalToType) typed")
                            .font(.app(.caption))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if fieldFocused {
                            Button {
                                fieldFocused = false
                            } label: {
                                Image(systemName: "keyboard.chevron.compact.down")
                                    .font(.app(.body))
                                    .foregroundStyle(Color.appAccent)
                            }
                            .accessibilityLabel("Hide keyboard")
                        }
                    }
                }

                #if DEBUG
                    Button("Skip (debug — random score)") {
                        var perWord: [Int: Bool] = [:]
                        for wordIdx in maskedIndices {
                            perWord[wordIdx] = Bool.random()
                        }
                        let correct = perWord.values.count(where: { $0 })
                        onContinue(correct, progress.totalToType, perWord)
                    }
                    .font(.app(.caption))
                    .foregroundStyle(.tertiary)
                #endif
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.lg)
        }
        .onAppear { fieldFocused = true }
    }

    @ViewBuilder
    private func wordCell(wordIndex: Int, word: String) -> some View {
        if let typingIdx = progress.typingIndex(forWord: wordIndex) {
            TypedWordCell(
                word: word,
                typedChar: progress.typedChar(forWord: wordIndex),
                correctness: progress.isCorrect(forWord: wordIndex),
                isCurrent: typingIdx == progress.currentTypingIndex && !progress.isComplete,
            )
        } else {
            Text(word)
                .bibleWordStyle()
        }
    }
}

// MARK: - Preview

#Preview {
    let verse = """
    For God so loved the world that he gave his one and only Son,
    that whoever believes in him shall not perish but have eternal life.
    """
    let words = verse.split(separator: " ", omittingEmptySubsequences: true)
    ActivityView(
        activityName: "Preview",
        reference: "John 3:16",
        passageText: verse,
        maskedIndices: Array(words.indices),
        instruction: "Type the first letter of each word.",
        onContinue: { _, _, _ in },
    )
    .environment(\.font, .app())
}
