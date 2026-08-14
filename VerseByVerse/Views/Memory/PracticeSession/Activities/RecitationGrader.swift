//
//  RecitationGrader.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 8/9/26.
//

import Foundation

/// Grades a finalized speech transcript against a passage's expected words.
/// Pure and audio-free — `VerbalActivityView` builds one once recording
/// stops. Aligns words with an LCS-based diff (not positional comparison) so
/// a single dropped or misheard word doesn't cascade into failing every
/// subsequent word, the way a naive index-by-index compare would.
nonisolated struct RecitationGrader {
    let expectedWords: [String]
    let transcript: String

    /// Correctness of every expected word, keyed like `TypingProgress.perWordCorrectness`.
    var perWordCorrectness: [Int: Bool] {
        let expected = expectedWords.map(Self.normalize)
        let matched = Self.lcsMatchedIndices(expected, spokenWords)
        var result: [Int: Bool] = [:]
        for index in expected.indices {
            result[index] = matched.contains(index)
        }
        return result
    }

    var correctCount: Int {
        perWordCorrectness.values.count(where: { $0 })
    }

    var totalCount: Int {
        expectedWords.count
    }

    private var spokenWords: [String] {
        transcript
            .split(whereSeparator: \.isWhitespace)
            .map { Self.normalize(String($0)) }
            .filter { !$0.isEmpty }
    }

    private static func normalize(_ word: String) -> String {
        word.lowercased().filter(\.isLetter)
    }

    /// Indices into `expected` that participate in the longest common subsequence with `spoken`.
    private static func lcsMatchedIndices(_ expected: [String], _ spoken: [String]) -> Set<Int> {
        guard !expected.isEmpty, !spoken.isEmpty else { return [] }
        let expectedCount = expected.count
        let spokenCount = spoken.count
        var lengths = Array(repeating: Array(repeating: 0, count: spokenCount + 1), count: expectedCount + 1)
        for expectedIndex in stride(from: expectedCount - 1, through: 0, by: -1) {
            for spokenIndex in stride(from: spokenCount - 1, through: 0, by: -1) {
                lengths[expectedIndex][spokenIndex] = expected[expectedIndex] == spoken[spokenIndex]
                    ? lengths[expectedIndex + 1][spokenIndex + 1] + 1
                    : max(lengths[expectedIndex + 1][spokenIndex], lengths[expectedIndex][spokenIndex + 1])
            }
        }

        var matched: Set<Int> = []
        var expectedIndex = 0
        var spokenIndex = 0
        while expectedIndex < expectedCount, spokenIndex < spokenCount {
            if expected[expectedIndex] == spoken[spokenIndex] {
                matched.insert(expectedIndex)
                expectedIndex += 1
                spokenIndex += 1
            } else if lengths[expectedIndex + 1][spokenIndex] >= lengths[expectedIndex][spokenIndex + 1] {
                expectedIndex += 1
            } else {
                spokenIndex += 1
            }
        }
        return matched
    }
}
