//
//  TypingProgressTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 10/5/26.
//

import Foundation
import Testing
@testable import VerseByVerse

/// Pins how passage words split around the typed letter and which words get
/// masked. Regression: `“This` used to render as `[T]This` because the cell
/// dropped the leading quote instead of the `T`.
@Suite("Typing progress")
struct TypingProgressTests {
    // MARK: - Word parts

    @Test func `plain word splits after its first letter`() {
        expectParts("world", leading: "", key: "w", trailing: "orld")
    }

    @Test func `leading quote stays before the typed letter`() {
        expectParts("“This", leading: "“", key: "T", trailing: "his")
        expectParts("(about", leading: "(", key: "a", trailing: "bout")
    }

    @Test func `trailing punctuation stays in the remainder`() {
        expectParts("it.”", leading: "", key: "i", trailing: "t.”")
    }

    @Test func `word starting with a digit is typed by that digit`() {
        expectParts("153", leading: "", key: "1", trailing: "53")
    }

    @Test func `punctuation-only token has nothing to type`() {
        let dash = TypedWordParts("—")
        #expect(dash.key == nil)
        #expect(!dash.isTypeable)
        #expect(dash.leading == "—")
    }

    // MARK: - Masking

    @Test func `punctuation-only tokens are never masked`() {
        let words = ["walk", "—", "in", "”"]
        #expect(TypingProgress.typeableIndices(in: words) == [0, 2])
    }

    @Test func `every other word alternates over typeable words only`() {
        let words = ["a", "—", "b", "c", "d"]
        #expect(TypingProgress.everyOtherIndices(in: words, phase: 0) == [0, 3])
        #expect(TypingProgress.everyOtherIndices(in: words, phase: 1) == [2, 4])
    }

    // MARK: - Correctness

    @Test func `typing the letter after a leading quote is correct`() {
        let progress = TypingProgress(passageText: "saying, “This is", maskedIndices: [1], inputText: "t")
        #expect(progress.isCorrect(forWord: 1) == true)
    }

    @Test func `typing the leading digit is correct`() {
        let progress = TypingProgress(passageText: "of 153 fish", maskedIndices: [1], inputText: "1")
        #expect(progress.isCorrect(forWord: 1) == true)
    }

    private func expectParts(
        _ word: String,
        leading: String,
        key: Character,
        trailing: String,
        sourceLocation: SourceLocation = #_sourceLocation,
    ) {
        let parts = TypedWordParts(word)
        #expect(parts.leading == leading, sourceLocation: sourceLocation)
        #expect(parts.key == key, sourceLocation: sourceLocation)
        #expect(parts.trailing == trailing, sourceLocation: sourceLocation)
    }
}
