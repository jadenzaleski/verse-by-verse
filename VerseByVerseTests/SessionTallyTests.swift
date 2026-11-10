//
//  SessionTallyTests.swift
//  VerseByVerseTests
//

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
