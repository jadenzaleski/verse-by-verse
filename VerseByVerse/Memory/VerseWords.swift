//
//  VerseWords.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/11/26.
//

import CryptoKit
import Foundation

/// The canonical word list of a verse: the words and nothing else. Used to
/// record *which* words were missed (as positions) and to tell later whether
/// those positions still describe the text on screen.
///
/// A canonical word is a whitespace-separated token reduced to its lowercase
/// letters and digits, so `“Thy` , `thy` and `Thy,` are all `thy`, and `God’s`
/// and `God's` are both `gods`. Tokens with no letter or digit (a lone `—`)
/// are not words and are dropped. Punctuation, capitalization and spacing never
/// change the list; a different, added, removed, merged or split word does.
///
/// Verse text is never stored (licensing): only positions and a one-way
/// fingerprint of this list are.
nonisolated enum VerseWords {
    /// The canonical words of `text`, in order.
    static func canonical(_ text: String) -> [String] {
        text.split(whereSeparator: \.isWhitespace).compactMap { reduce(String($0)) }
    }

    /// For each whitespace token, the index of its word in the canonical list,
    /// or `nil` when the token holds no word. The practice flow tracks tokens
    /// (punctuation marks included); this maps them to stable word positions.
    static func positions(ofTokens tokens: [String]) -> [Int?] {
        var next = 0
        return tokens.map { token in
            guard reduce(token) != nil else { return nil }
            defer { next += 1 }
            return next
        }
    }

    /// A short one-way hash of the canonical words (16 hex characters). Equal
    /// fingerprints mean the same words in the same order.
    static func fingerprint(of text: String) -> String {
        let digest = SHA256.hash(data: Data(canonical(text).joined(separator: " ").utf8))
        return digest.prefix(8).map { byte in
            let hex = String(byte, radix: 16)
            return byte < 0x10 ? "0" + hex : hex
        }.joined()
    }

    private static func reduce(_ token: String) -> String? {
        let word = token.precomposedStringWithCanonicalMapping.lowercased()
            .filter { $0.isLetter || $0.isNumber }
        return word.isEmpty ? nil : word
    }
}
