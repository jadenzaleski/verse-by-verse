//
//  AccessibilityLabelTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 10/9/26.
//

import Testing
@testable import VerseByVerse

/// What VoiceOver says during the typing activities. The key rule: an
/// unanswered word is only ever "blank" — the hidden word is never spoken —
/// and a wrong answer says "Incorrect", never the expected letter.
@Suite("Typing VoiceOver")
struct AccessibilityLabelTests {
    private func cell(
        _ word: String = "said,",
        typed: Character? = nil,
        correct: Bool? = nil,
        current: Bool = false,
    ) -> String {
        TypedWordCell(word: word, typedChar: typed, correctness: correct, isCurrent: current).accessibilityDescription
    }

    // MARK: - Word cells

    @Test func `unanswered word is blank and never spoken`() {
        #expect(cell() == "blank")
        #expect(!cell().contains("said"))
    }

    @Test func `current word says so`() {
        #expect(cell(current: true) == "blank, current word")
    }

    @Test func `answered words report their result`() {
        #expect(cell("And", typed: "a", correct: true) == "And, correct")
        #expect(cell("said,", typed: "x", correct: false) == "said, incorrect")
        #expect(cell("“This", typed: "t", correct: true) == "This, correct")
    }

    // MARK: - Announcements

    private func progress(_ typed: String) -> TypingProgress {
        // Masked words: "And" (a), "said," (s), "the" (t).
        TypingProgress(passageText: "And Jesus said, Make the men", maskedIndices: [0, 2, 4], inputText: typed)
    }

    @Test func `nothing is announced before the first answer`() {
        #expect(progress("").latestAnswerAnnouncement == nil)
    }

    @Test func `a right answer says correct`() {
        let result = progress("a").latestAnswerAnnouncement
        #expect(result?.message == "Correct")
        #expect(result?.isCorrect == true)
    }

    @Test func `a wrong answer says incorrect and never the expected letter`() {
        let result = progress("ax").latestAnswerAnnouncement
        #expect(result?.message == "Incorrect")
        #expect(result?.isCorrect == false)
    }

    @Test func `the last answer adds the score`() {
        let result = progress("axt").latestAnswerAnnouncement
        #expect(result?.message == "Correct. All words typed. 2 of 3 correct.")
    }
}
