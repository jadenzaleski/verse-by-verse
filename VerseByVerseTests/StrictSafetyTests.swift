//
//  StrictSafetyTests.swift
//  VerseByVerseTests
//

import Foundation
import Testing
@testable import VerseByVerse

/// Pins values that were produced by code since rewritten without raw
/// pointers or C-variadic formatting, so the rewrite can't silently change them.
struct StrictSafetyTests {
    @Test func `hex string is two lowercase digits per byte`() {
        #expect([UInt8]([0x00, 0x0F, 0xAB, 0xFF]).hexString == "000fabff")
        #expect([UInt8]().hexString.isEmpty)
    }

    /// Values recorded from the original `withUnsafeBytes { $0.load(as: Int.self) }`
    /// implementation; they drive deterministic per-user visuals, so they must not move.
    @Test(arguments: [
        ("John 3:16", 7_917_003_954_766_128_791),
        ("", 1_449_310_910_991_872_227),
        ("Romans 8:28-39", -4_966_976_051_570_480_048),
        ("Memorize ✝︎ Psalm 23", 867_992_046_758_731_588),
    ])
    func `stable seed matches the original raw-load value`(text: String, expected: Int) {
        #expect(text.stableSeed == expected)
    }
}
