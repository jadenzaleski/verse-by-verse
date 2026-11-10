//
//  HexString.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/9/26.
//

import Foundation

nonisolated extension Sequence<UInt8> {
    /// Lowercase hex, two digits per byte (`[0x0f, 0xab]` → `"0fab"`).
    /// Used for hash fingerprints; avoids C-variadic `String(format:)`,
    /// which strict memory safety flags.
    var hexString: String {
        map { byte in
            let digits = String(byte, radix: 16)
            return byte < 0x10 ? "0" + digits : digits
        }.joined()
    }
}
