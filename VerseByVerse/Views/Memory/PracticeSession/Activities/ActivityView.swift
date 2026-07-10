//
//  ActivityView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/8/26.
//

import SwiftUI

struct ActivityView: View {
    let activityName: String
    let reference: String
    let verseText: String
    /// Ordered word indices the user must type the first letter of.
    let maskedIndices: [Int]
    let instruction: String
    /// Show the rest of each masked word as a faded hint (true for Every Other Word).
    let showWordHints: Bool
    /// Called with (correct, total, per-word correctness keyed by word index)
    /// when the user taps Continue.
    let onContinue: (Int, Int, [Int: Bool]) -> Void

    @State private var inputText = ""
    @FocusState private var fieldFocused: Bool

    private var words: [String] {
        verseText.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    }

    private var typingIndexMap: [Int: Int] {
        Dictionary(uniqueKeysWithValues: maskedIndices.enumerated().map { ($0.element, $0.offset) })
    }

    private var totalToType: Int {
        maskedIndices.count
    }

    private var currentTypingIndex: Int {
        min(inputText.count, totalToType)
    }

    private var isComplete: Bool {
        inputText.count >= totalToType
    }

    private func typedChar(at idx: Int) -> Character? {
        guard idx < inputText.count else { return nil }
        return inputText[inputText.index(inputText.startIndex, offsetBy: idx)]
    }

    private func expectedLetter(of word: String) -> Character? {
        word.first { $0.isLetter }
    }

    private func isCorrect(at typingIdx: Int) -> Bool? {
        guard typingIdx < maskedIndices.count else { return nil }
        let wordIdx = maskedIndices[typingIdx]
        guard wordIdx < words.count else { return nil }
        guard let typed = typedChar(at: typingIdx) else { return nil }
        return typed.lowercased() == expectedLetter(of: words[wordIdx])?.lowercased()
    }

    private var correctCount: Int {
        (0 ..< totalToType).count(where: { isCorrect(at: $0) == true })
    }

    /// Correctness of every masked word, keyed by its index in `words`.
    private var perWordCorrectness: [Int: Bool] {
        var result: [Int: Bool] = [:]
        for (typingIdx, wordIdx) in maskedIndices.enumerated() {
            result[wordIdx] = isCorrect(at: typingIdx) == true
        }
        return result
    }

    private var scoreColor: Color {
        let pct = totalToType > 0 ? Double(correctCount) / Double(totalToType) : 0
        if pct >= 0.8 { return .green }
        if pct >= 0.5 { return .orange }
        return .red
    }

    var body: some View {
        VStack(spacing: 0) {
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
                        ForEach(Array(words.enumerated()), id: \.offset) { idx, word in
                            wordCell(wordIndex: idx, word: word)
                        }
                    }
                }
                .padding(AppSpacing.xl)
                .padding(.top, AppSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onTapGesture { fieldFocused = true }

            // Hidden field that captures keystrokes
            TextField("", text: $inputText)
                .opacity(0)
                .frame(height: 1)
                .focused($fieldFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .onChange(of: inputText) { _, new in
                    if new.count > totalToType {
                        inputText = String(new.prefix(totalToType))
                    }
                }

            VStack(spacing: AppSpacing.md) {
                if isComplete {
                    HStack(spacing: AppSpacing.xs) {
                        Text("\(correctCount) of \(totalToType)")
                            .font(.app(.body, weight: .semibold))
                            .foregroundStyle(scoreColor)
                        Text("correct")
                            .font(.app(.body))
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        onContinue(correctCount, totalToType, perWordCorrectness)
                    } label: {
                        Text("Continue")
                            .font(.app(.body, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppRadius.md)
                            .background(Color.appAccent, in: RoundedRectangle(cornerRadius: AppRadius.md))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack {
                        Text("\(currentTypingIndex) of \(totalToType) typed")
                            .font(.app(.caption))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            fieldFocused = true
                        } label: {
                            Label("Show keyboard", systemImage: "keyboard")
                                .font(.app(.caption))
                                .foregroundStyle(Color.appAccent)
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
                        onContinue(correct, totalToType, perWord)
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
        if let typingIdx = typingIndexMap[wordIndex] {
            TypedWordCell(
                word: word,
                typedChar: typedChar(at: typingIdx),
                correctness: isCorrect(at: typingIdx),
                isCurrent: typingIdx == currentTypingIndex && !isComplete,
                showHint: showWordHints,
            )
        } else {
            Text(word)
                .font(.app(.body))
        }
    }
}

// MARK: - Word tile

private struct TypedWordCell: View {
    let word: String
    let typedChar: Character?
    let correctness: Bool?
    let isCurrent: Bool
    let showHint: Bool

    var body: some View {
        HStack(spacing: 1) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(boxColor)
                    .frame(width: 16, height: 20)
                if let typed = typedChar {
                    Text(String(typed).uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                } else if isCurrent {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 2, height: 14)
                }
            }

            if word.count > 1 {
                ZStack(alignment: .leading) {
                    // Reserve the final width so layout doesn't shift when typing starts
                    Text(remainder)
                        .font(.app(.body))
                        .fontDesign(.monospaced)
                        .lineLimit(1)
                        .allowsTightening(false)
                        .hidden()

                    if typedChar != nil {
                        Text(remainder)
                            .font(.app(.body))
                            .fontDesign(.monospaced)
                            .lineLimit(1)
                            .allowsTightening(false)
                            .foregroundStyle(correctness == true ? Color.appSuccess : Color.appDestructive)
                    } else if showHint {
                        Text(remainder)
                            .font(.app(.body))
                            .fontDesign(.monospaced)
                            .lineLimit(1)
                            .allowsTightening(false)
                            .foregroundStyle(Color.secondary.opacity(0.25))
                    } else {
                        Text(String(repeating: "_", count: remainder.count))
                            .font(.app(.body))
                            .fontDesign(.monospaced)
                            .lineLimit(1)
                            .allowsTightening(false)
                            .foregroundStyle(Color.secondary.opacity(0.35))
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }
        }
    }

    private var remainder: String {
        String(word.dropFirst())
    }

    private var boxColor: Color {
        if let correct = correctness {
            return correct ? .appSuccess : .appDestructive
        }
        return isCurrent ? Color.appAccent.opacity(0.6) : Color.secondary.opacity(0.2)
    }
}

// MARK: - Flow layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        layout(subviews: subviews, width: proposal.width ?? 300).size
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let result = layout(subviews: subviews, width: bounds.width)
        for (i, pos) in result.positions.enumerated() {
            subviews[i].place(
                at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y),
                proposal: .unspecified,
            )
        }
    }

    private func layout(subviews: Subviews, width: CGFloat) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxY: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxY = max(maxY, y + size.height)
        }

        return (CGSize(width: width, height: maxY), positions)
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
        verseText: verse,
        maskedIndices: Array(words.indices),
        instruction: "Type the first letter of each word.",
        showWordHints: false,
        onContinue: { _, _, _ in },
    )
    .environment(\.font, .app())
}
