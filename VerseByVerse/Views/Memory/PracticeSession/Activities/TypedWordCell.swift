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
/// typed first character, plus the word's remaining letters revealed,
/// hinted, or blanked out depending on activity state.
struct TypedWordCell: View {
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
                        .bibleWordStyle()
                        .lineLimit(1)
                        .allowsTightening(false)
                        .hidden()

                    if typedChar != nil {
                        Text(remainder)
                            .bibleWordStyle()
                            .lineLimit(1)
                            .allowsTightening(false)
                            .foregroundStyle(correctness == true ? Color.appSuccess : Color.appDestructive)
                    } else if showHint {
                        Text(remainder)
                            .bibleWordStyle()
                            .lineLimit(1)
                            .allowsTightening(false)
                            .foregroundStyle(Color.secondary.opacity(0.25))
                    } else {
                        Text(String(repeating: "_", count: remainder.count))
                            .bibleWordStyle()
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

#Preview {
    HStack(spacing: 6) {
        TypedWordCell(word: "loved", typedChar: "l", correctness: true, isCurrent: false, showHint: false)
        TypedWordCell(word: "wrold", typedChar: "w", correctness: false, isCurrent: false, showHint: false)
        TypedWordCell(word: "world", typedChar: nil, correctness: nil, isCurrent: true, showHint: false)
        TypedWordCell(word: "that", typedChar: nil, correctness: nil, isCurrent: false, showHint: true)
        TypedWordCell(word: "he", typedChar: nil, correctness: nil, isCurrent: false, showHint: false)
    }
    .padding()
}
