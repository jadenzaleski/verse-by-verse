//
//  SessionTallyTests.swift
//  VerseByVerseTests
//

import SwiftUI
import Testing
@testable import VerseByVerse

/// Pins which steps count toward a session's score: only unaided recall.
struct SessionTallyTests {
    @Test func `only unaided steps are scored`() {
        #expect(ActivityStep.verbalRecite.isScored)
        #expect(ActivityStep.everyWord(allowsRetry: true).isScored)
        #expect(!ActivityStep.everyOtherWord(phase: 0).isScored)
        #expect(!ActivityStep.everyOtherWord(phase: 1).isScored)
        #expect(!ActivityStep.everyWordRetry.isScored)
    }

    @Test func `practice and retry add nothing`() {
        var tally = SessionTally(verseCount: 1, wordOwners: [0, 0, 0, 0])
        let allRight: [Int: Bool] = [0: true, 1: true, 2: true, 3: true]

        tally.record(step: .everyOtherWord(phase: 0), correct: 2, total: 2, perWord: [0: true, 2: true])
        tally.record(step: .everyOtherWord(phase: 1), correct: 2, total: 2, perWord: [1: true, 3: true])
        let firstPass: [Int: Bool] = [0: true, 1: false, 2: true, 3: false]
        tally.record(step: .everyWord(allowsRetry: true), correct: 2, total: 4, perWord: firstPass)
        tally.record(step: .everyWordRetry, correct: 4, total: 4, perWord: allRight)

        // Only the first Every Word pass counts: 2 of 4, not the easy rounds or the retry.
        #expect(tally.correct == 2)
        #expect(tally.total == 4)
        #expect(tally.verseCorrect == [2])
        #expect(tally.verseTotal == [4])
    }

    @Test func `words are attributed to their verse`() {
        var tally = SessionTally(verseCount: 2, wordOwners: [0, 0, 1, 1, 1])
        tally.record(
            step: .everyWord(allowsRetry: true),
            correct: 3, total: 5,
            perWord: [0: true, 1: true, 2: false, 3: false, 4: true],
        )
        #expect(tally.verseCorrect == [2, 1])
        #expect(tally.verseTotal == [2, 3])
    }

    @Test func `recite and every word pool by word count`() {
        var tally = SessionTally(verseCount: 1, wordOwners: [0, 0])
        tally.record(step: .verbalRecite, correct: 2, total: 2, perWord: [0: true, 1: true])
        tally.record(step: .everyWord(allowsRetry: true), correct: 1, total: 2, perWord: [0: true, 1: false])
        #expect(tally.correct == 3)
        #expect(tally.total == 4)
    }
}

/// Missed-word positions: what's recorded, and when it can be trusted.
struct MissedWordTests {
    @Test func `canonical words ignore punctuation, case and spacing`() {
        let plain = "For God so loved the world"
        let messy = "“For   GOD, so loved —  the world.”"
        #expect(VerseWords.canonical(plain) == VerseWords.canonical(messy))
        #expect(VerseWords.fingerprint(of: plain) == VerseWords.fingerprint(of: messy))
        #expect(VerseWords.canonical("God’s love") == VerseWords.canonical("God's love"))
    }

    @Test func `a changed word changes the fingerprint`() {
        let original = VerseWords.fingerprint(of: "For God so loved the world")
        #expect(original != VerseWords.fingerprint(of: "For God so loved this world"))
        #expect(original != VerseWords.fingerprint(of: "For God loved the world"))
        #expect(original != VerseWords.fingerprint(of: "For God so loved the world also"))
        #expect(original.count == 16)
    }

    @Test func `punctuation-only tokens are not words`() {
        #expect(VerseWords.positions(ofTokens: ["Hello", "—", "world."]) == [0, nil, 1])
    }

    @Test func `tally records missed positions from scored steps only`() {
        var tally = SessionTally(verseCount: 2, wordOwners: [0, 0, 0, 1, 1], wordPositions: [0, nil, 1, 0, 1])
        tally.record(step: .everyOtherWord(phase: 0), correct: 0, total: 1, perWord: [0: false])
        tally.record(
            step: .everyWord(allowsRetry: true),
            correct: 2, total: 5,
            perWord: [0: true, 1: false, 2: false, 3: false, 4: true],
        )
        // The dash (index 1) has no position; index 2 is the verse's second word.
        #expect(tally.verseMissed == [[1], [0]])
    }

    @Test func `positions only apply to the text they were recorded against`() {
        let text = "For God so loved the world"
        let review = VerseReview()
        review.missedWordIndices = [2, 4]
        review.textFingerprint = VerseWords.fingerprint(of: text)

        #expect(review.missedWordIndices(forText: "“For God, so loved the world.”") == [2, 4])
        #expect(review.missedWordIndices(forText: "For God so loved this world") == nil)

        let unknown = VerseReview()
        unknown.missedWordIndices = [1]
        #expect(unknown.missedWordIndices(forText: text) == nil)
    }
}

/// The heatmap's input: per-word miss counts for the text on screen.
@MainActor
struct WordHeatmapTests {
    private func selection(_ text: String) -> BibleSelection {
        BibleSelection(
            translation: "KJV", book: "John", startChapter: 3, startVerse: 16, endChapter: 3, endVerse: 16,
            verses: [SelectionVerse(id: "1", book: "John", chapter: 3, verse: 16, text: text)],
            fumsTokens: [],
        )
    }

    private func verse(reviewed text: String, missing positions: [[Int]]) -> Verse {
        let verse = Verse(book: "John", chapter: 3, number: 16)
        for missed in positions {
            let review = VerseReview()
            review.missedWordIndices = missed
            review.textFingerprint = VerseWords.fingerprint(of: text)
            review.verse = verse
        }
        return verse
    }

    @Test func `counts misses per word across reviews`() {
        let text = "For God so loved the world"
        let verse = verse(reviewed: text, missing: [[1, 3], [3], []])
        let summary = verse.missSummary(forText: text)
        #expect(summary.reviewCount == 3)
        #expect(summary.counts == [1: 1, 3: 2])

        let data = WordHeatmap.build(selection: selection("For God so “loved” the world."), verses: [verse])
        #expect(data.hasHistory)
        #expect(data.maxMisses == 2)
        #expect(data.tokens.map(\.misses) == [0, 0, 1, 0, 2, 0, 0]) // verse number, then six words
        #expect(data.tokens.first?.kind == .verseNumber)
    }

    @Test func `character ranges match the annotated text`() {
        let selection = BibleSelection(
            translation: "KJV", book: "John", startChapter: 3, startVerse: 16, endChapter: 3, endVerse: 17,
            verses: [
                SelectionVerse(id: "1", book: "John", chapter: 3, verse: 16, text: "For God so  loved —"),
                SelectionVerse(id: "2", book: "John", chapter: 3, verse: 17, text: "For God sent."),
            ],
            fumsTokens: [],
        )
        // `annotatedText`: number, space, text; one space between verses.
        let plain = Array("16 For God so  loved — 17 For God sent.")
        let data = WordHeatmap.build(selection: selection, verses: [])
        #expect(data.tokenAtCharacter.count == plain.count)
        for token in data.tokens {
            #expect(String(plain[token.characterRange]) == token.text)
        }
        #expect(data.tokens.map(\.kind) == [
            .verseNumber, .word, .word, .word, .word, .mark, .verseNumber, .word, .word, .word,
        ])
        #expect(data.token(atCharacter: 0)?.text == "16")
        #expect(data.token(atCharacter: 2) == nil) // a space
    }

    @Test func `a changed verse shows no history`() {
        let verse = verse(reviewed: "For God so loved the world", missing: [[1]])
        let data = WordHeatmap.build(selection: selection("For God so loved this world"), verses: [verse])
        #expect(!data.hasHistory)
        #expect(data.maxMisses == 0)
        #expect(data.tokens.allSatisfy { $0.misses == 0 && !$0.hasHistory })
    }

    @Test func `colors run green to red`() {
        func rgb(_ color: Color) -> [Float] {
            let resolved = color.resolve(in: EnvironmentValues())
            return [resolved.red, resolved.green, resolved.blue]
        }
        /// Mixing goes through a color space, so allow for rounding.
        func close(_ lhs: [Float], _ rhs: [Float]) -> Bool {
            zip(lhs, rhs).allSatisfy { abs($0 - $1) < 0.02 }
        }
        let green = rgb(Color.appSuccess)
        let red = rgb(Color.appDestructive)
        #expect(close(rgb(WordHeatmap.color(misses: 0, maxMisses: 4)), green))
        #expect(close(rgb(WordHeatmap.color(misses: 0, maxMisses: 0)), green))
        #expect(close(rgb(WordHeatmap.color(misses: 4, maxMisses: 4)), red))
        let middle = rgb(WordHeatmap.color(misses: 2, maxMisses: 4))
        #expect(!close(middle, green) && !close(middle, red))
    }
}
