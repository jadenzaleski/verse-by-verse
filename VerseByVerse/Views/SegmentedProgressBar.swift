//
//  SegmentedProgressBar.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 4/30/26.
//

import SwiftUI

struct SegmentedProgressBar: View {
    let totalSegments: Int
    /// Number of fully completed segments. The segment at this index is the active one.
    let completedSegments: Int

    /// The filled segments' colour. For a Memory Score pass ``Color/score(_:)``.
    var fill: Color = .appAccent
    /// When true, completed segments are dimmed and the segment at `completedSegments` is highlighted as active.
    var highlightCurrent: Bool = false
    /// VoiceOver reads the bar as one element: this label and value (default
    /// "x of y"), since the segments themselves carry no meaning.
    var accessibilityLabel: String = "Progress"
    var accessibilityValue: String?
    var emptyColor: Color = .gray.opacity(0.2)
    var spacing: CGFloat = 5
    var height: CGFloat = 5

    private func segmentColor(at index: Int) -> Color {
        if index < completedSegments {
            highlightCurrent ? fill.opacity(0.4) : fill
        } else if index == completedSegments, highlightCurrent {
            fill
        } else {
            emptyColor
        }
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0 ..< totalSegments, id: \.self) { index in
                RoundedRectangle(cornerRadius: 5)
                    .fill(segmentColor(at: index))
                    .frame(maxWidth: .infinity, maxHeight: height)
                    .animation(
                        .easeInOut(duration: 0.35).delay(animationDelay(for: index)),
                        value: completedSegments,
                    )
                    .animation(.easeInOut(duration: 0.35), value: totalSegments)
                    .transition(unsafe .opacity.combined(with: .scale(scale: 0.7)))
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue ?? "\(completedSegments) of \(totalSegments)")
    }

    private func animationDelay(for index: Int) -> Double {
        if index < completedSegments {
            Double(index) * 0.05
        } else {
            Double(totalSegments - 1 - index) * 0.05
        }
    }
}

#Preview {
    @Previewable @State var completed: Double = 2

    VStack(spacing: AppSpacing.xxl) {
        SegmentedProgressBar(totalSegments: 6, completedSegments: Int(completed))
        SegmentedProgressBar(totalSegments: 6, completedSegments: Int(completed), fill: .appAccent)
        SegmentedProgressBar(totalSegments: 6,
                             completedSegments: Int(completed),
                             fill: .appAccent,
                             highlightCurrent: true)
        Slider(value: $completed, in: 0 ... 6, step: 1)
    }
    .padding()
    .environment(\.font, .app())
}
