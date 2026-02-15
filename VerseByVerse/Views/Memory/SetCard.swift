//
//  SetCard.swift
//  VerseByVerse
//
//  Rewritten to use MeshGradient directly
//

import SwiftUI

struct SetCard: View {
    // Public configuration
    var title: String
    var passageCount: Int
    var verseCount: Int
    var positionSeed: Int
    var colorShuffleSeed: Int
    var colorPallette: MeshPalette

    private let cornerRadius: CGFloat = 20
    private let jitter: Float = 0.25

    init(
        title: String = "The Gospels",
        passageCount: Int = 18,
        verseCount: Int = 26,
        positionSeed: Int = 123,
        colorShuffleSeed: Int = 1234,
        colorPallette: MeshPalette = MeshPalette.all[0],

    ) {
        self.title = title
        self.passageCount = passageCount
        self.verseCount = verseCount
        self.positionSeed = positionSeed
        self.colorShuffleSeed = colorShuffleSeed
        self.colorPallette = colorPallette
    }

    var body: some View {
        /*
         Mesh Grid Bezier Points (p):
         ---------
         | 0 1 2 |
         | 3 4 5 |
         | 6 7 8 |
         ---------
         */
        // This is how far of the ideal spot the point should be
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

        VStack(alignment: .leading, spacing: 0) {
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
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            Text(title)
                .font(.app(.headline))
                .padding(.top, 5)

            HStack {
                Text("\(passageCount) Passages")
                Spacer(minLength: 5)
                Text("\(verseCount) V")
            }
            .font(.app(.caption))
            .foregroundStyle(.secondary)
        }
        .lineLimit(1)
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

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed))
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible(minimum: 100, maximum: 300), spacing: 10)], spacing: 10) {
            SetCard(title: "The Gospels", passageCount: 24, verseCount: 120, positionSeed: 1)
            SetCard(title: "Paul's Epistles", passageCount: 13, verseCount: 87, positionSeed: 12)
            SetCard(title: "Psalms of Ascent", passageCount: 15, verseCount: 45, positionSeed: 3)
            SetCard(title: "Wisdom Literature", passageCount: 5, verseCount: 250, positionSeed: 42)
            SetCard(title: "Pentateuch", passageCount: 5, verseCount: 585, positionSeed: 12345)
            SetCard(title: "Major Prophets", passageCount: 5, verseCount: 300, positionSeed: 987)
            SetCard(title: "Minor Prophets", passageCount: 12, verseCount: 150, positionSeed: 654)
            SetCard(title: "Johannine Writings very", passageCount: 3, verseCount: 60, positionSeed: 316)
        }
        .padding()
    }
    .environment(\.font, .app())
}
