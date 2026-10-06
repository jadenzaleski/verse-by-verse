//
//  TypingProgress.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/8/26.
//

import Foundation

/// A passage word split into the part the user types and the punctuation
/// around it. Punctuation is structure, not memory work: it's always shown
/// and never scored or colored. `“This,` → (`“`, `T`, `his`, `,`).
/// A word with no letter or digit (a lone `—` or `”`) has no `key` and is
/// never masked.
struct TypedWordParts: Equatable {
    /// Punctuation before the typed character, e.g. `“` or `(`.
    let leading: String
    /// The first letter or digit — the character the user types.
    let key: Character?
    /// Letters (and inner marks like `’` or `-`) after the key, up to the
    /// trailing punctuation.
    let rest: String
    /// Punctuation after the last letter or digit, e.g. `.”` or `,`.
    let trailing: String

    init(_ word: String) {
        func isWordCharacter(_ char: Character) -> Bool {
            char.isLetter || char.isNumber
        }

        guard let keyIndex = word.firstIndex(where: isWordCharacter),
              let lastIndex = word.lastIndex(where: isWordCharacter)
        else {
            leading = word
            key = nil
            rest = ""
            trailing = ""
            return
        }
        leading = String(word[..<keyIndex])
        key = word[keyIndex]
        rest = keyIndex == lastIndex ? "" : String(word[word.index(after: keyIndex) ... lastIndex])
        trailing = String(word[word.index(after: lastIndex)...])
    }

    var isTypeable: Bool {
        key != nil
    }
}

/// Derives per-character typing correctness for a masked-word activity
/// (Every Other Word / Every Word) from the raw passage text, which word
/// indices are masked, and what's been typed so far.
struct TypingProgress {
    let words: [String]
    let maskedIndices: [Int]
    let inputText: String

    init(passageText: String, maskedIndices: [Int], inputText: String) {
        words = passageText.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        self.maskedIndices = maskedIndices
        self.inputText = inputText
    }

    /// Indices of the words that can be masked — those with a letter or digit.
    static func typeableIndices(in words: [String]) -> [Int] {
        words.indices.filter { TypedWordParts(words[$0]).isTypeable }
    }

    /// Every other typeable word, starting with the first (`phase` 0) or
    /// second (`phase` 1). Punctuation-only tokens don't break the alternation.
    static func everyOtherIndices(in words: [String], phase: Int) -> [Int] {
        typeableIndices(in: words).enumerated()
            .filter { $0.offset % 2 == phase }
            .map(\.element)
    }

    private var typingIndexMap: [Int: Int] {
        Dictionary(uniqueKeysWithValues: maskedIndices.enumerated().map { ($0.element, $0.offset) })
    }

    var totalToType: Int {
        maskedIndices.count
    }

    var currentTypingIndex: Int {
        min(inputText.count, totalToType)
    }

    var isComplete: Bool {
        inputText.count >= totalToType
    }

    /// Position within the typed input for a given word index, if that word is masked.
    func typingIndex(forWord wordIndex: Int) -> Int? {
        typingIndexMap[wordIndex]
    }

    func typedChar(forWord wordIndex: Int) -> Character? {
        guard let typingIdx = typingIndexMap[wordIndex] else { return nil }
        return typedChar(at: typingIdx)
    }

    func isCorrect(forWord wordIndex: Int) -> Bool? {
        guard let typingIdx = typingIndexMap[wordIndex] else { return nil }
        return isCorrect(at: typingIdx)
    }

    var correctCount: Int {
        (0 ..< totalToType).count(where: { isCorrect(at: $0) == true })
    }

    /// Correctness of every masked word, keyed by its index in `words`.
    var perWordCorrectness: [Int: Bool] {
        var result: [Int: Bool] = [:]
        for (typingIdx, wordIdx) in maskedIndices.enumerated() {
            result[wordIdx] = isCorrect(at: typingIdx) == true
        }
        return result
    }

    private func typedChar(at idx: Int) -> Character? {
        guard idx < inputText.count else { return nil }
        return inputText[inputText.index(inputText.startIndex, offsetBy: idx)]
    }

    private func expectedLetter(of word: String) -> Character? {
        TypedWordParts(word).key
    }

    private func isCorrect(at typingIdx: Int) -> Bool? {
        guard typingIdx < maskedIndices.count else { return nil }
        let wordIdx = maskedIndices[typingIdx]
        guard wordIdx < words.count else { return nil }
        guard let typed = typedChar(at: typingIdx) else { return nil }
        return typed.lowercased() == expectedLetter(of: words[wordIdx])?.lowercased()
    }
}
