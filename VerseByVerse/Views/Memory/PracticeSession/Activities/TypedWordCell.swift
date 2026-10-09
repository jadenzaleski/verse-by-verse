//
//  TypedWordCell.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/8/26.
//

import SwiftUI

extension Text {
    /// The single seam for how bible verse text is styled while typing
    /// activities render it word-by-word (`ActivityView`, `TypedWordCell`).
    /// Prose rendering elsewhere in the app goes through
    /// `BibleSelection.annotatedText`, which bakes in `.font(.bible())`
    /// directly — this is that same font, for the word-level case where a
    /// single `Text`/`AttributedString` isn't an option.
    func bibleWordStyle() -> Text {
        font(.bible(.body))
    }
}

/// A single word tile in a masked-word typing activity: a letter box for the
/// typed first character, plus the word's remaining letters revealed or
/// blanked out depending on activity state.
struct TypedWordCell: View {
    let word: String
    let typedChar: Character?
    let correctness: Bool?
    let isCurrent: Bool

    @ScaledMetric(relativeTo: .body) private var boxWidth: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var boxHeight: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var letterSize: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var cursorHeight: CGFloat = 12

    var body: some View {
        HStack(spacing: 0) {
            punctuation(parts.leading)

            HStack(spacing: 1) {
                ZStack {
                    box
                        .frame(width: boxWidth, height: boxHeight)
                        .padding(.horizontal, 1)

                    if let typed = typedChar {
                        Text(String(typed).uppercased())
                            .font(.system(size: letterSize, weight: .bold, design: .monospaced))
                            .foregroundStyle(isWrong ? Color.appDestructive : .white)
                    } else if isCurrent {
                        // cursor
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 2, height: cursorHeight)
                    }
                }

                if !parts.rest.isEmpty {
                    Text(parts.rest)
                        .bibleWordStyle()
                        .lineLimit(1)
                        .allowsTightening(false)
                        .hidden()
                        .overlay(alignment: .leading) {
                            if typedChar != nil {
                                Text(parts.rest)
                                    .bibleWordStyle()
                                    .lineLimit(1)
                                    .allowsTightening(false)
                                    .foregroundStyle(correctness == true ? Color.appSuccess : Color.appDestructive)
                            } else {
                                Capsule()
                                    .fill(Color.secondary.opacity(0.35))
                                    .frame(height: 1.5)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            }
                        }
                        .fixedSize(horizontal: true, vertical: false)
                }
            }

            punctuation(parts.trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    /// One VoiceOver element per word, with its state. An unanswered word is
    /// only ever "blank" — the hidden word is never spoken, same as on screen.
    var accessibilityDescription: String {
        guard typedChar != nil else {
            return isCurrent ? "blank, current word" : "blank"
        }
        // Letters only — punctuation around the word would read as "said,, incorrect".
        let spoken = parts.key.map { String($0) + parts.rest } ?? word
        return "\(spoken), \(correctness == true ? "correct" : "incorrect")"
    }

    @ViewBuilder
    private func punctuation(_ text: String) -> some View {
        if !text.isEmpty {
            Text(text)
                .bibleWordStyle()
                .fixedSize()
        }
    }

    /// Split into the typed letter and the punctuation around it, so `“This,`
    /// renders as `“[T]his,` with the quote and comma outside the blank.
    private var parts: TypedWordParts {
        TypedWordParts(word)
    }

    private var isWrong: Bool {
        correctness == false
    }

    /// Wrong answers get a light red tint and a dashed red border; every
    /// other state is a plain filled box.
    @ViewBuilder
    private var box: some View {
        if isWrong {
            RoundedRectangle(cornerRadius: AppRadius.xxs)
                .fill(Color.appDestructive.opacity(0.15))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.xxs)
                        .strokeBorder(Color.appDestructive, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                }
        } else {
            RoundedRectangle(cornerRadius: AppRadius.xxs)
                .fill(boxColor)
        }
    }

    private var boxColor: Color {
        if let correct = correctness {
            return correct ? .appSuccess : .appDestructive
        }
        return isCurrent ? Color.appAccent.opacity(0.6) : Color.secondary.opacity(0.2)
    }
}

#Preview {
    Grid(alignment: .center, horizontalSpacing: 10, verticalSpacing: 10) {
        TypedWordCell(word: "wrold", typedChar: "w", correctness: true, isCurrent: false)
        TypedWordCell(word: "wrold", typedChar: "w", correctness: false, isCurrent: false)
        TypedWordCell(word: "world", typedChar: nil, correctness: nil, isCurrent: true)
        TypedWordCell(word: "“This", typedChar: "t", correctness: true, isCurrent: false)
        TypedWordCell(word: "it.”", typedChar: "x", correctness: false, isCurrent: false)
        TypedWordCell(word: "(about", typedChar: nil, correctness: nil, isCurrent: false)
        TypedWordCell(word: "Son,", typedChar: nil, correctness: nil, isCurrent: true)
        TypedWordCell(word: "he", typedChar: nil, correctness: nil, isCurrent: false)
    }
    .padding()
}
