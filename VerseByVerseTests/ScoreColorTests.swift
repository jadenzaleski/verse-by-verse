//
//  ScoreColorTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 11/20/26.
//

import SwiftUI
import Testing
@testable import VerseByVerse

/// One rule colours every percentage in the app, so the bands are pinned here.
struct ScoreColorTests {
    @Test func `bands are red below 60, orange below 80, green from 80`() {
        #expect(Color.score(0) == .red)
        #expect(Color.score(0.59) == .red)
        #expect(Color.score(0.6) == .orange)
        #expect(Color.score(0.79) == .orange)
        #expect(Color.score(0.8) == .green)
        #expect(Color.score(1) == .green)
    }

    @Test func `out of range values clamp to the end bands`() {
        #expect(Color.score(-0.5) == .red)
        #expect(Color.score(1.5) == .green)
    }
}
