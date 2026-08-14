//
//  RecitationGraderTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 8/9/26.
//

import Foundation
import Testing
@testable import VerseByVerse

/// Behavioral tests for grading a live speech transcript against a verse's
/// expected words — pure word-alignment logic, no audio involved.
struct RecitationGraderTests {
    private let johnThreeSixteen = [
        "For", "God", "so", "loved", "the", "world", "that", "he", "gave",
        "his", "one", "and", "only", "Son,",
    ]

    @Test func `exact match grades every word correct`() {
        let grader = RecitationGrader(
            expectedWords: johnThreeSixteen,
            transcript: "For God so loved the world that he gave his one and only Son",
        )

        #expect(grader.correctCount == johnThreeSixteen.count)
        #expect(grader.totalCount == johnThreeSixteen.count)
        #expect(!grader.perWordCorrectness.values.contains(false))
    }

    @Test func `missing words are marked incorrect without shifting the rest`() {
        // "the world" dropped entirely.
        let grader = RecitationGrader(
            expectedWords: johnThreeSixteen,
            transcript: "For God so loved that he gave his one and only Son",
        )

        #expect(grader.perWordCorrectness[4] == false) // the
        #expect(grader.perWordCorrectness[5] == false) // world
        // Everything else still lines up correctly.
        for index in [0, 1, 2, 3, 6, 7, 8, 9, 10, 11, 12, 13] {
            #expect(grader.perWordCorrectness[index] == true, "word at \(index) should still grade correct")
        }
        #expect(grader.correctCount == johnThreeSixteen.count - 2)
    }

    @Test func `extra misheard words do not cascade-fail subsequent correct words`() {
        // A naive positional compare would fail every word after the insertion
        // ("um") shifts the alignment. LCS-based grading should not.
        let grader = RecitationGrader(
            expectedWords: johnThreeSixteen,
            transcript: "For God so um loved the world that he gave his one and only Son",
        )

        #expect(grader.correctCount == johnThreeSixteen.count)
        #expect(!grader.perWordCorrectness.values.contains(false))
    }

    @Test func `punctuation and case differences still grade correct`() {
        let grader = RecitationGrader(
            expectedWords: johnThreeSixteen,
            transcript: "for god SO loved THE world that HE gave his one AND only son",
        )

        #expect(grader.correctCount == johnThreeSixteen.count)
    }

    @Test func `empty transcript grades everything incorrect`() {
        let grader = RecitationGrader(expectedWords: johnThreeSixteen, transcript: "")

        #expect(grader.correctCount == 0)
        #expect(grader.totalCount == johnThreeSixteen.count)
        #expect(!grader.perWordCorrectness.values.contains(true))
    }

    @Test func `repeated word said only once counts once`() {
        let grader = RecitationGrader(expectedWords: ["the", "the", "world"], transcript: "the world")

        #expect(grader.correctCount == 2)
        #expect(grader.totalCount == 3)
        #expect(grader.perWordCorrectness[2] == true) // "world" always lines up
    }

    @Test func `single word verse`() {
        let exact = RecitationGrader(expectedWords: ["Jesus"], transcript: "Jesus")
        #expect(exact.correctCount == 1)

        let wrong = RecitationGrader(expectedWords: ["Jesus"], transcript: "wept")
        #expect(wrong.correctCount == 0)
    }
}
