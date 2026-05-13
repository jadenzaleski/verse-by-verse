//
//  SegmentedProgressBar.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 4/30/26.
//

import SwiftUI

struct SegmentedProgressBar: View {
    let totalSegments: Int
    let completedSegments: Int

    var emptyColor: Color = .gray.opacity(0.2)
    var spacing: CGFloat = 5
    var height: CGFloat = 5

    var body: some View {
        let fillColor: Color = if Double(completedSegments) / Double(totalSegments) <= 0.33 {
            .red
        } else if Double(completedSegments) / Double(totalSegments) <= 0.66 {
            .orange
        } else {
            .green
        }

        HStack(spacing: spacing) {
            ForEach(0 ..< totalSegments, id: \.self) { index in
                SegmentBlock(
                    filled: index < completedSegments,
                    fillColor: fillColor,
                    emptyColor: emptyColor,
                    height: height,
                )
                .frame(maxWidth: .infinity)
                .animation(
                    .easeInOut(duration: 0.35)
                        .delay(animationDelay(for: index)),
                    value: completedSegments,
                )
            }
        }
        .animation(nil, value: fillColor)
    }

    private func animationDelay(for index: Int) -> Double {
        if index < completedSegments {
            Double(index) * 0.1
        } else {
            Double(totalSegments - 1 - index) * 0.1
        }
    }
}

struct SegmentBlock: View {
    let filled: Bool
    let fillColor: Color
    let emptyColor: Color
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 5.0)
                    .fill(emptyColor)

                RoundedRectangle(cornerRadius: 5.0)
                    .fill(fillColor)
                    .mask(
                        HStack(spacing: 0) {
                            if filled {
                                Rectangle()
                            }
                        },
                    )
                    .frame(width: geo.size.width, alignment: .leading)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 5.0)
                            .fill(fillColor)
                            .frame(width: filled ? geo.size.width : 0),
                        alignment: .leading,
                    )
            }
        }
        .frame(height: height)
    }
}

#Preview {
    @Previewable @State var progress: Double = 4

    VStack {
        SegmentedProgressBar(totalSegments: 10, completedSegments: Int(progress))
        Slider(
            value: $progress,
            in: 0 ... 10,
            step: 1,
        )
    }
    .environment(\.font, .app())
}
