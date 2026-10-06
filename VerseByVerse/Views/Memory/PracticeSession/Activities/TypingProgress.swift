//
//  TypingProgress.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/8/26.
//

import Foundation

/// A passage word split around the character the user types.
struct TypedWordParts: Equatable {
    let leading: String
    let key: Character?
    let trailing: String

    init(_ word: String) {
        guard let keyIndex = word.firstIndex(where: { $0.isLetter || $0.isNumber }) else {
            leading = word
            key = nil
            trailing = ""
            return
        }
        leading = String(word[..<keyIndex])
        key = word[keyIndex]
        trailing = String(word[word.index(after: keyIndex)...])
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
