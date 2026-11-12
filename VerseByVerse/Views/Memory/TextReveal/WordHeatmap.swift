//
//  WordHeatmap.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/11/26.
//

import SwiftUI

/// One piece of a selection's text: a verse number, a word, or a bare mark
/// such as a dash.
nonisolated struct HeatmapToken: Identifiable, Equatable {
    enum Kind { case verseNumber, word, mark }

    let id: Int
    let text: String
    let kind: Kind
    /// Times this word was missed; 0 for anything that isn't a word.
    let misses: Int
    /// Whether the word's verse has practice history for this exact text.
    /// Without it the word is left uncolored rather than claimed "never missed".
    let hasHistory: Bool
    /// Where the token sits in `BibleSelection.annotatedText`, in characters.
    let characterRange: Range<Int>
}

/// What the heatmap draws over a selection's text.
nonisolated struct HeatmapData: Equatable {
    var tokens: [HeatmapToken] = []
    /// The most any one word was missed; the red end of the scale.
    var maxMisses = 0
    /// True when at least one verse has history to show.
    var hasHistory = false
    /// Character offset in the annotated text → index into `tokens` (-1 for
    /// spaces). Lets the text renderer find the word behind a glyph.
    var tokenAtCharacter: [Int] = []

    func token(atCharacter offset: Int) -> HeatmapToken? {
        guard tokenAtCharacter.indices.contains(offset) else { return nil }
        let index = tokenAtCharacter[offset]
        return index >= 0 ? tokens[index] : nil
    }

    /// What VoiceOver hears for the heatmap: the most-missed words.
    var accessibilitySummary: String {
        let missed = tokens.filter { $0.misses > 0 }
        guard !missed.isEmpty else { return "No missed words" }
        return missed
            .sorted { $0.misses > $1.misses }
            .prefix(10)
            .map { "\($0.text), missed \($0.misses)" }
            .joined(separator: "; ")
    }
}

enum WordHeatmap {
    /// Builds the tokens for `selection`, counting misses from each tracked
    /// verse's reviews. Misses are matched to words by position, and only for
    /// reviews recorded against the text now on screen (see ``VerseWords``).
    /// Character ranges follow `BibleSelection.annotatedText`: each verse is its
    /// number, a space, then its text, with a space between verses.
    static func build(selection: BibleSelection, verses: [Verse]) -> HeatmapData {
        var verseByRef: [String: Verse] = [:]
        for verse in verses {
            verseByRef["\(verse.chapter):\(verse.number)"] = verse
        }

        var data = HeatmapData()
        var offset = 0
        for (index, selectionVerse) in selection.verses.enumerated() {
            if index > 0 {
                offset += 1
            }
            let summary = verseByRef["\(selectionVerse.chapter):\(selectionVerse.verse)"]?
                .missSummary(forText: selectionVerse.text) ?? MissSummary()
            let hasHistory = summary.reviewCount > 0
            data.hasHistory = data.hasHistory || hasHistory

            let number = "\(selectionVerse.verse)"
            data.tokens.append(HeatmapToken(
                id: data.tokens.count, text: number, kind: .verseNumber, misses: 0, hasHistory: false,
                characterRange: offset ..< offset + number.count,
            ))
            offset += number.count + 1

            let pieces = pieces(of: selectionVerse.text, startingAt: offset)
            let positions = VerseWords.positions(ofTokens: pieces.map(\.text))
            for (piece, position) in zip(pieces, positions) {
                let misses = position.flatMap { summary.counts[$0] } ?? 0
                data.maxMisses = max(data.maxMisses, misses)
                data.tokens.append(HeatmapToken(
                    id: data.tokens.count, text: piece.text, kind: position == nil ? .mark : .word,
                    misses: misses, hasHistory: hasHistory, characterRange: piece.range,
                ))
            }
            offset += selectionVerse.text.count
        }

        data.tokenAtCharacter = Array(repeating: -1, count: offset)
        for (index, token) in data.tokens.enumerated() {
            for character in token.characterRange {
                data.tokenAtCharacter[character] = index
            }
        }
        return data
    }

    /// The space-separated pieces of `text` and where each starts and ends, offset by `start`.
    private static func pieces(of text: String, startingAt start: Int) -> [(text: String, range: Range<Int>)] {
        var result: [(text: String, range: Range<Int>)] = []
        var current = ""
        var currentStart = 0
        for (index, character) in text.enumerated() {
            if character == " " {
                if !current.isEmpty {
                    result.append((current, start + currentStart ..< start + index))
                    current = ""
                }
            } else {
                if current.isEmpty {
                    currentStart = index
                }
                current.append(character)
            }
        }
        if !current.isEmpty {
            result.append((current, start + currentStart ..< start + text.count))
        }
        return result
    }

    /// Green for a word never missed, fading to red for the most-missed word.
    static func color(misses: Int, maxMisses: Int) -> Color {
        let fraction = maxMisses > 0 ? Double(misses) / Double(maxMisses) : 0
        return Color.appSuccess.mix(with: .appDestructive, by: fraction)
    }
}

/// The key under the heatmapped text: the green-to-red scale, or a hint when
/// there's nothing to show yet.
struct HeatmapLegend: View {
    let data: HeatmapData

    var body: some View {
        if data.hasHistory {
            HStack(spacing: AppSpacing.sm) {
                Text("0")
                LinearGradient(
                    colors: [
                        WordHeatmap.color(misses: 0, maxMisses: 1),
                        WordHeatmap.color(misses: 1, maxMisses: 2),
                        WordHeatmap.color(misses: 1, maxMisses: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing,
                )
                .frame(width: 80, height: 6)
                .clipShape(Capsule())
                Text("\(max(data.maxMisses, 1)) missed")
            }
            .font(.app(.caption2))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        } else {
            Text("Practice this text to see which words you miss.")
                .font(.app(.footnote))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Heat 0 / 0.5 / 1") {
    let passage = PreviewData.samplePassage
    let selection = PreviewData.bibleStore.selections[passage.selectionKey]
    return ScrollView {
        if let selection {
            let data = WordHeatmap.build(selection: selection, verses: passage.orderedVerses)
            VStack(spacing: AppSpacing.xl) {
                ForEach([0.0, 0.5, 1.0], id: \.self) { heat in
                    selection.annotatedText
                        .textRenderer(SelectionTextRenderer(
                            state: TextRevealState(expansion: 1, heat: heat),
                            collapsedLines: 5,
                            heatmap: data,
                        ))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                HeatmapLegend(data: data)
            }
            .padding()
        }
    }
}
