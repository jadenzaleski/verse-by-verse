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
        expectParts("world", leading: "", key: "w", rest: "orld", trailing: "")
    }

    @Test func `leading quote and paren stay outside the typed letter`() {
        expectParts("“This", leading: "“", key: "T", rest: "his", trailing: "")
        expectParts("(about", leading: "(", key: "a", rest: "bout", trailing: "")
    }

    @Test func `trailing punctuation is split from the letters`() {
        expectParts("it.”", leading: "", key: "i", rest: "t", trailing: ".”")
        expectParts("Son,", leading: "", key: "S", rest: "on", trailing: ",")
        expectParts("nothing),", leading: "", key: "n", rest: "othing", trailing: "),")
    }

    @Test func `punctuation on both sides of a one-letter word`() {
        expectParts("“I,”", leading: "“", key: "I", rest: "", trailing: ",”")
        expectParts("a,", leading: "", key: "a", rest: "", trailing: ",")
    }

    @Test func `inner marks stay with the letters`() {
        expectParts("God’s,", leading: "", key: "G", rest: "od’s", trailing: ",")
        expectParts("well-known.", leading: "", key: "w", rest: "ell-known", trailing: ".")
    }

    @Test func `word starting with a digit is typed by that digit`() {
        expectParts("153", leading: "", key: "1", rest: "53", trailing: "")
    }

    @Test func `punctuation-only token has nothing to type`() {
        let dash = TypedWordParts("—")
        #expect(dash.key == nil)
        #expect(!dash.isTypeable)
        #expect(dash.leading == "—")
        #expect(dash.rest.isEmpty && dash.trailing.isEmpty)
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

    @Test func `punctuation never counts as the answer`() {
        // “Have (about it.” — only H / a / i are ever expected.
        let progress = TypingProgress(
            passageText: "“Have (about it.”",
            maskedIndices: [0, 1, 2],
            inputText: "hai",
        )
        #expect(progress.correctCount == 3)
        #expect(TypingProgress(passageText: "“Have", maskedIndices: [0], inputText: "“").isCorrect(forWord: 0) == false)
    }

    @Test func `typing the leading digit is correct`() {
        let progress = TypingProgress(passageText: "of 153 fish", maskedIndices: [1], inputText: "1")
        #expect(progress.isCorrect(forWord: 1) == true)
    }

    // MARK: - Append-only input

    private func type(_ old: String, _ new: String, onto current: String, limit: Int = 5) -> String {
        TypingProgress.appending(fieldChangeFrom: old, to: new, onto: current, limit: limit)
    }

    @Test func `typing a letter appends it`() {
        #expect(type("a", "ab", onto: "a") == "ab")
        #expect(type("", "a", onto: "") == "a")
    }

    @Test func `backspace changes nothing`() {
        #expect(type("ab", "a", onto: "ab") == "ab")
        #expect(type("a", "", onto: "a") == "a")
    }

    @Test func `typing after a backspace still counts`() {
        // The field shrank from "ab" to "a" (ignored), so it's now behind the
        // answer — the next letter must still append, not be dropped.
        #expect(type("a", "ac", onto: "ab") == "abc")
    }

    @Test func `input is capped at the number of words to type`() {
        #expect(type("ab", "abcd", onto: "ab", limit: 3) == "abc")
        #expect(type("abc", "abcd", onto: "abc", limit: 3) == "abc")
    }

    private func expectParts(
        _ word: String,
        leading: String,
        key: Character,
        rest: String,
        trailing: String,
        sourceLocation: SourceLocation = #_sourceLocation,
    ) {
        let parts = TypedWordParts(word)
        #expect(parts.leading == leading, sourceLocation: sourceLocation)
        #expect(parts.key == key, sourceLocation: sourceLocation)
        #expect(parts.rest == rest, sourceLocation: sourceLocation)
        #expect(parts.trailing == trailing, sourceLocation: sourceLocation)
    }
}
