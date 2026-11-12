//
//  RevealWindow.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/11/26.
//

import SwiftUI

/// Sizes the text's window frame by frame as the reveal animates. The text
/// itself stays laid out at full size (giving it less height would truncate it
/// with an ellipsis) and isn't clipped: untyped glyphs simply aren't drawn, and
/// the window stays a line ahead of the typing (see ``TextRevealMotion``).
struct RevealWindow: ViewModifier, Animatable {
    var state: TextRevealState
    let collapsedHeight: CGFloat
    let fullHeight: CGFloat
    let hiddenLines: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { state.animatableData }
        set { state.animatableData = newValue }
    }

    private var height: CGFloat? {
        guard collapsedHeight > 0, fullHeight > 0 else { return nil }
        let opening = TextRevealMotion.windowOpening(reveal: state.reveal, hiddenLines: hiddenLines)
        let base = collapsedHeight + (fullHeight - collapsedHeight) * opening
        return base * (1 + TextRevealMotion.heatStretch * state.spread)
    }

    func body(content: Content) -> some View {
        content.frame(height: height, alignment: .top)
    }
}
