//
//  TextRevealMotionTests.swift
//  VerseByVerseTests
//

import Foundation
import Testing
@testable import VerseByVerse

/// Pins the timing rules the text card's animations depend on. Each of these
/// was a visible glitch before it was a rule.
struct TextRevealMotionTests {
    private let steps = (0 ... 200).map { Double($0) / 200 }

    @Test(arguments: [1, 2, 5, 12])
    func `a line is fully open before its first glyph is typed`(hiddenLines: Int) {
        let limit = 5
        let lineCount = limit + hiddenLines
        for reveal in steps {
            let opening = TextRevealMotion.windowOpening(reveal: reveal, hiddenLines: Double(hiddenLines))
            // The window shows the collapsed lines plus this many hidden ones.
            let openLines = opening * Double(hiddenLines)
            for line in limit ..< lineCount {
                let typed = TextRevealMotion.typed(
                    line: line, collapsedLines: limit, lineCount: lineCount, reveal: reveal,
                )
                guard typed > 0 else { continue }
                #expect(openLines >= Double(line - limit + 1) - 1e-9, "line \(line) typed before it was open")
            }
        }
    }

    @Test(arguments: [1, 3, 8])
    func `the window is full as the last line starts, and typing ends with the animation`(hiddenLines: Int) {
        let limit = 5
        let lineCount = limit + hiddenLines
        let lastStarts = Double(hiddenLines) / Double(hiddenLines + 1)
        #expect(TextRevealMotion.windowOpening(reveal: lastStarts, hiddenLines: Double(hiddenLines)) == 1)
        let last = lineCount - 1
        #expect(TextRevealMotion.typed(line: last, collapsedLines: limit, lineCount: lineCount, reveal: 1) == 1)
        let lastAtStart = TextRevealMotion.typed(
            line: last, collapsedLines: limit, lineCount: lineCount, reveal: lastStarts,
        )
        #expect(lastAtStart == 0)
    }

    @Test func `collapsed lines are always there and hidden ones start empty`() {
        #expect(TextRevealMotion.typed(line: 4, collapsedLines: 5, lineCount: 8, reveal: 0) == 1)
        #expect(TextRevealMotion.typed(line: 5, collapsedLines: 5, lineCount: 8, reveal: 0) == 0)
        #expect(TextRevealMotion.windowOpening(reveal: 0, hiddenLines: 3) == 0)
        #expect(TextRevealMotion.windowOpening(reveal: 0.4, hiddenLines: 0) == 1)
    }

    @Test(arguments: [true, false])
    func `spread and pen run 0 to 1 in either direction`(turningOn: Bool) {
        // Matching ends mean switching direction at rest never jumps.
        #expect(TextRevealMotion.spread(heat: 0, turningOn: turningOn) == 0)
        #expect(TextRevealMotion.spread(heat: 1, turningOn: turningOn) == 1)
        #expect(TextRevealMotion.pen(heat: 0, turningOn: turningOn) == 0)
        #expect(TextRevealMotion.pen(heat: 1, turningOn: turningOn) == 1)
        var previous = (spread: 0.0, pen: 0.0)
        for heat in steps {
            let now = (
                spread: TextRevealMotion.spread(heat: heat, turningOn: turningOn),
                pen: TextRevealMotion.pen(heat: heat, turningOn: turningOn),
            )
            #expect(now.spread >= previous.spread && now.pen >= previous.pen)
            previous = now
        }
    }

    @Test func `turning on, the lines spread before the pen starts`() {
        let penStarts = steps.first { TextRevealMotion.pen(heat: $0, turningOn: true) > 0 } ?? 1
        #expect(TextRevealMotion.spread(heat: penStarts, turningOn: true) >= 0.75)
    }

    @Test func `turning off, the card shrinks the whole way with no pause`() {
        // Every step of the animation closes the spacing a little more.
        var previous = TextRevealMotion.spread(heat: 1, turningOn: false)
        for heat in steps.reversed().dropFirst() {
            let spread = TextRevealMotion.spread(heat: heat, turningOn: false)
            #expect(spread < previous, "no shrinking at heat \(heat)")
            previous = spread
        }
    }

    @Test func `the pen colors lines in reading order`() {
        #expect(TextRevealMotion.painted(line: 0, lineCount: 4, pen: 0.25) == 1)
        #expect(TextRevealMotion.painted(line: 1, lineCount: 4, pen: 0.25) == 0)
        #expect(TextRevealMotion.painted(line: 1, lineCount: 4, pen: 0.375) == 0.5)
    }

    @Test func `the toggle returns as the heatmap finishes turning off`() {
        #expect(TextRevealMotion.toggleReturnDelay < TextRevealMotion.heatDuration)
        let returned = TextRevealMotion.toggleReturnDelay + TextRevealMotion.toggleReturnDuration
        #expect(returned >= TextRevealMotion.heatDuration)
    }

    @Test func `hidden lines are estimated from measured heights`() {
        #expect(TextRevealMotion.hiddenLines(fullHeight: 160, collapsedHeight: 100, collapsedLines: 5) == 3)
        #expect(TextRevealMotion.hiddenLines(fullHeight: 100, collapsedHeight: 100, collapsedLines: 5) == 0)
        #expect(TextRevealMotion.hiddenLines(fullHeight: 160, collapsedHeight: 0, collapsedLines: 5) == 0)
    }

    @Test func `the heatmap reveals hidden lines too`() {
        #expect(TextRevealState(isExpanded: false, showsHeatmap: true).reveal == 1)
        #expect(TextRevealState(isExpanded: false, showsHeatmap: false).reveal == 0)
        #expect(TextRevealState(expansion: 0.2, heat: 0.7).reveal == 0.7)
    }
}
