//
//  TextRevealMotion.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/11/26.
//

import SwiftUI

/// Every timing rule of the text card's two animations, in one place. The
/// renderer (``SelectionTextRenderer``) and the window (``RevealWindow``) both
/// read from here, so the pieces that have to line up can't drift apart.
/// `TextRevealMotionTests` pins the invariants.
///
/// - **Show / Hide** types the hidden lines in glyph by glyph. The window opens
///   one line ahead of the typing: hidden line `k` (of `m`) is typed while
///   `reveal` runs from `(k+1)/(m+1)` to `(k+2)/(m+1)`, and the window reaches
///   full height just as the last line starts, so a line is never cut through.
/// - **Heatmap** spreads the lines apart to make room for the miss counts and
///   draws the color on with a pen that sweeps the lines in reading order.
///   Turning on, the lines spread first and the pen follows; turning off, both
///   run together so the card shrinks in one motion.
nonisolated enum TextRevealMotion {
    // MARK: Durations

    /// How long the heatmap takes to turn on or off.
    static let heatDuration: Double = 0.6

    /// When the Show/Hide button returns after the heatmap turns off: just
    /// before the text settles, so it lands with it.
    static let toggleReturnDelay: Double = heatDuration - 0.1
    static let toggleReturnDuration: Double = 0.15

    /// Show/Hide: quick, a little longer for more lines, never sluggish.
    static func revealDuration(hiddenLines: Double) -> Double {
        min(0.3 + 0.06 * max(hiddenLines, 0), 0.9)
    }

    static func revealAnimation(hiddenLines: Double) -> Animation {
        .smooth(duration: revealDuration(hiddenLines: hiddenLines))
    }

    static let heatAnimation: Animation = .smooth(duration: heatDuration)

    static let toggleReturnAnimation: Animation = .easeOut(duration: toggleReturnDuration)
        .delay(toggleReturnDelay)

    // MARK: Show / Hide

    /// Lines past the collapsed limit, estimated from measured heights (the
    /// renderer counts them exactly from the layout).
    static func hiddenLines(fullHeight: CGFloat, collapsedHeight: CGFloat, collapsedLines: Int) -> Double {
        guard collapsedHeight > 0, collapsedLines > 0 else { return 0 }
        let lineHeight = collapsedHeight / Double(collapsedLines)
        return max(((fullHeight - collapsedHeight) / lineHeight).rounded(), 0)
    }

    /// How much of line `index` is typed, 0…1. Lines inside the collapsed limit
    /// are always fully there.
    static func typed(line index: Int, collapsedLines: Int, lineCount: Int, reveal: Double) -> Double {
        let limit = max(collapsedLines, 1)
        guard index >= limit else { return 1 }
        let hidden = Double(max(lineCount - limit, 0))
        return clamp(reveal * (hidden + 1) - Double(index - limit + 1))
    }

    /// How open the window is, 0 (collapsed) … 1 (full): one line ahead of the typing.
    static func windowOpening(reveal: Double, hiddenLines: Double) -> Double {
        guard hiddenLines > 0 else { return 1 }
        return clamp(reveal * (hiddenLines + 1) / hiddenLines)
    }

    // MARK: Heatmap

    /// How much taller the text grows at full spread, as a fraction of its
    /// height: one extra gap per line for the counts to sit in.
    static let heatStretch: CGFloat = 0.75

    /// How far the lines have spread. Turning on, they open in the first third
    /// so the counts have room before the pen arrives; turning off, they close
    /// steadily alongside the eraser.
    static func spread(heat: Double, turningOn: Bool) -> Double {
        clamp(turningOn ? heat * 3 : heat)
    }

    /// Where the pen is, as a fraction of all lines. Turning on, it starts once
    /// the lines have mostly spread; turning off, it erases the whole way.
    static func pen(heat: Double, turningOn: Bool) -> Double {
        clamp(turningOn ? (heat - 0.25) / 0.75 : heat)
    }

    /// How much of line `index` the pen has colored, 0…1, sweeping lines in order.
    static func painted(line index: Int, lineCount: Int, pen: Double) -> Double {
        clamp(pen * Double(lineCount) - Double(index))
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

/// Where both animations are right now. One value feeds the renderer and the
/// window, so they always agree.
nonisolated struct TextRevealState: Equatable {
    /// Show/Hide, 0 (collapsed) … 1 (expanded).
    var expansion: Double
    /// Heatmap, 0 (off) … 1 (on).
    var heat: Double
    /// Whether the heatmap is turning on (or on) rather than off; the two
    /// directions pace the spread and the pen differently.
    var heatingUp: Bool

    init(isExpanded: Bool, showsHeatmap: Bool) {
        expansion = isExpanded ? 1 : 0
        heat = showsHeatmap ? 1 : 0
        heatingUp = showsHeatmap
    }

    /// A fixed frame of the animation, for previews.
    init(expansion: Double, heat: Double, heatingUp: Bool = true) {
        self.expansion = expansion
        self.heat = heat
        self.heatingUp = heatingUp
    }

    /// How far the hidden lines are revealed. The heatmap needs every line, so
    /// it reveals them too.
    var reveal: Double {
        min(max(max(expansion, heat), 0), 1)
    }

    var spread: Double {
        TextRevealMotion.spread(heat: heat, turningOn: heatingUp)
    }

    var pen: Double {
        TextRevealMotion.pen(heat: heat, turningOn: heatingUp)
    }

    /// What SwiftUI interpolates: expansion and heat.
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(expansion, heat) }
        set {
            expansion = newValue.first
            heat = newValue.second
        }
    }
}
