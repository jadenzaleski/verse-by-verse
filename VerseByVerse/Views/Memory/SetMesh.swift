//
//  SetMesh.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/19/26.
//

import SwiftUI

struct SetMesh: View {
    let colorPallette: MeshPalette
    let colorShuffleSeed: Int
    let positionSeed: Int
    private let jitter: Float = 0.25

    var body: some View {
        /*
         Mesh Grid Bezier Points (p):
         ---------
         | 0 1 2 |
         | 3 4 5 |
         | 6 7 8 |
         ---------
         */
        // Row 1
        // p0 (0.0, 0.0)
        let p0Position: SIMD2<Float> = [0.0, 0.0]
        let p0LeadingControlPoint: SIMD2<Float> = [0.0, 0.0]
        let p0TopControlPoint: SIMD2<Float> = [0.0, 0.0]
        let p0TrailingControlPoint: SIMD2<Float> = [jitteredNumber(0.25), 0.0]
        let p0BottomControlPoint: SIMD2<Float> = [0.0, jitteredNumber(0.25)]
        // p1 (0.5, 0.0)
        let p1Position: SIMD2<Float> = [jitteredNumber(0.5), 0.0]
        let p1LeadingControlPoint: SIMD2<Float> = [jitteredNumber(0.25), 0.0]
        let p1TopControlPoint: SIMD2<Float> = [0.5, 0.0]
        let p1TrailingControlPoint: SIMD2<Float> = [jitteredNumber(0.75), 0.0]
        let p1BottomControlPoint: SIMD2<Float> = [jitteredNumber(0.5), jitteredNumber(0.25)]
        // p2
        let p2Position: SIMD2<Float> = [1.0, 0.0]
        let p2LeadingControlPoint: SIMD2<Float> = [jitteredNumber(0.75), 0.0]
        let p2TopControlPoint: SIMD2<Float> = [1.0, 0.0]
        let p2TrailingControlPoint: SIMD2<Float> = [1.0, 0.0]
        let p2BottomControlPoint: SIMD2<Float> = [1.0, jitteredNumber(0.25)]
        // Row 2
        // p3
        let p3Position: SIMD2<Float> = [0.0, jitteredNumber(0.5)]
        let p3LeadingControlPoint: SIMD2<Float> = [0.0, 0.5]
        let p3TopControlPoint: SIMD2<Float> = [0.0, jitteredNumber(0.25)]
        let p3TrailingControlPoint: SIMD2<Float> = [jitteredNumber(0.25), jitteredNumber(0.5)]
        let p3BottomControlPoint: SIMD2<Float> = [0.0, jitteredNumber(0.75)]
        // p4
        let p4Position: SIMD2<Float> = [jitteredNumber(0.5), jitteredNumber(0.5)]
        let p4LeadingControlPoint: SIMD2<Float> = [jitteredNumber(0.25), jitteredNumber(0.5)]
        let p4TopControlPoint: SIMD2<Float> = [jitteredNumber(0.5), jitteredNumber(0.25)]
        let p4TrailingControlPoint: SIMD2<Float> = [jitteredNumber(0.75), jitteredNumber(0.5)]
        let p4BottomControlPoint: SIMD2<Float> = [jitteredNumber(0.5), jitteredNumber(0.75)]
        // p5
        let p5Position: SIMD2<Float> = [1.0, jitteredNumber(0.5)]
        let p5LeadingControlPoint: SIMD2<Float> = [jitteredNumber(0.75), jitteredNumber(0.5)]
        let p5TopControlPoint: SIMD2<Float> = [1.0, jitteredNumber(0.5)]
        let p5TrailingControlPoint: SIMD2<Float> = [1.0, 0.5]
        let p5BottomControlPoint: SIMD2<Float> = [1.0, jitteredNumber(0.75)]
        // Row 3
        // p6
        let p6Position: SIMD2<Float> = [0.0, 1.0]
        let p6LeadingControlPoint: SIMD2<Float> = [0.0, 1.0]
        let p6TopControlPoint: SIMD2<Float> = [0.0, jitteredNumber(0.75)]
        let p6TrailingControlPoint: SIMD2<Float> = [jitteredNumber(0.25), 1.0]
        let p6BottomControlPoint: SIMD2<Float> = [0.0, 1.0]
        // p7
        let p7Position: SIMD2<Float> = [jitteredNumber(0.5), 1.0]
        let p7LeadingControlPoint: SIMD2<Float> = [jitteredNumber(0.25), 1.0]
        let p7TopControlPoint: SIMD2<Float> = [jitteredNumber(0.5), jitteredNumber(0.75)]
        let p7TrailingControlPoint: SIMD2<Float> = [jitteredNumber(0.75), 1.0]
        let p7BottomControlPoint: SIMD2<Float> = [0.5, 1.0]
        // p8
        let p8Position: SIMD2<Float> = [1.0, 1.0]
        let p8LeadingControlPoint: SIMD2<Float> = [jitteredNumber(0.75), 1.0]
        let p8TopControlPoint: SIMD2<Float> = [1.0, jitteredNumber(0.75)]
        let p8TrailingControlPoint: SIMD2<Float> = [1.0, 1.0]
        let p8BottomControlPoint: SIMD2<Float> = [1.0, 1.0]

            MeshGradient(
                width: 3,
                height: 3,
                bezierPoints: [
                    // Row 1 (top)
                    // p0
                    MeshGradient.BezierPoint(
                        position: p0Position,
                        leadingControlPoint: p0LeadingControlPoint,
                        topControlPoint: p0TopControlPoint,
                        trailingControlPoint: p0TrailingControlPoint,
                        bottomControlPoint: p0BottomControlPoint,
                    ),
                    // p1
                    MeshGradient.BezierPoint(
                        position: p1Position,
                        leadingControlPoint: p1LeadingControlPoint,
                        topControlPoint: p1TopControlPoint,
                        trailingControlPoint: p1TrailingControlPoint,
                        bottomControlPoint: p1BottomControlPoint,
                    ),
                    // p2
                    MeshGradient.BezierPoint(
                        position: p2Position,
                        leadingControlPoint: p2LeadingControlPoint,
                        topControlPoint: p2TopControlPoint,
                        trailingControlPoint: p2TrailingControlPoint,
                        bottomControlPoint: p2BottomControlPoint,
                    ),

                    // Row 2 (middle)
                    // p3
                    MeshGradient.BezierPoint(
                        position: p3Position,
                        leadingControlPoint: p3LeadingControlPoint,
                        topControlPoint: p3TopControlPoint,
                        trailingControlPoint: p3TrailingControlPoint,
                        bottomControlPoint: p3BottomControlPoint,
                    ),
                    // p4
                    MeshGradient.BezierPoint(
                        position: p4Position,
                        leadingControlPoint: p4LeadingControlPoint,
                        topControlPoint: p4TopControlPoint,
                        trailingControlPoint: p4TrailingControlPoint,
                        bottomControlPoint: p4BottomControlPoint,
                    ),
                    // p5
                    MeshGradient.BezierPoint(
                        position: p5Position,
                        leadingControlPoint: p5LeadingControlPoint,
                        topControlPoint: p5TopControlPoint,
                        trailingControlPoint: p5TrailingControlPoint,
                        bottomControlPoint: p5BottomControlPoint,
                    ),

                    // Row 3 (bottom)
                    // p6
                    MeshGradient.BezierPoint(
                        position: p6Position,
                        leadingControlPoint: p6LeadingControlPoint,
                        topControlPoint: p6TopControlPoint,
                        trailingControlPoint: p6TrailingControlPoint,
                        bottomControlPoint: p6BottomControlPoint,
                    ),
                    // p7
                    MeshGradient.BezierPoint(
                        position: p7Position,
                        leadingControlPoint: p7LeadingControlPoint,
                        topControlPoint: p7TopControlPoint,
                        trailingControlPoint: p7TrailingControlPoint,
                        bottomControlPoint: p7BottomControlPoint,
                    ),
                    // p8
                    MeshGradient.BezierPoint(
                        position: p8Position,
                        leadingControlPoint: p8LeadingControlPoint,
                        topControlPoint: p8TopControlPoint,
                        trailingControlPoint: p8TrailingControlPoint,
                        bottomControlPoint: p8BottomControlPoint,
                    ),
                ],
                colors: shuffledColors(from: colorPallette),
            )
    }

    private func jitteredNumber(_ number: Float) -> Float {
        var generator = SeededGenerator(seed: positionSeed)
        // set min and max to ensure our result cannot be out of bounds [0.0, 1.0]
        let minBound = max(0.0, number - jitter)
        let maxBound = min(1.0, number + jitter)
        return Float.random(in: minBound ... maxBound, using: &generator)
    }

    private func shuffledColors(from palette: MeshPalette) -> [Color] {
        var generator = SeededGenerator(seed: colorShuffleSeed)
        var colors = palette.colors

        colors.shuffle(using: &generator)
        return colors
    }
}

#Preview {
    SetMesh(colorPallette: .forest, colorShuffleSeed: 1, positionSeed: 1)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
}
