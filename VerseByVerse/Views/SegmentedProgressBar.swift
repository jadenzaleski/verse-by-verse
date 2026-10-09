//
//  SegmentedProgressBar.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 4/30/26.
//

import SwiftUI

enum ProgressBarFill {
    case dynamic
    case solid(Color)
}

struct SegmentedProgressBar: View {
    let totalSegments: Int
    /// Number of fully completed segments. The segment at this index is the active one.
    let completedSegments: Int

    var fill: ProgressBarFill = .dynamic
    /// When true, completed segments are dimmed and the segment at `completedSegments` is highlighted as active.
    var highlightCurrent: Bool = false
    /// VoiceOver reads the bar as one element: this label and value (default
    /// "x of y"), since the segments themselves carry no meaning.
    var accessibilityLabel: String = "Progress"
    var accessibilityValue: String?
    var emptyColor: Color = .gray.opacity(0.2)
    var spacing: CGFloat = 5
    var height: CGFloat = 5

    private var fillColor: Color {
        switch fill {
        case let .solid(color):
            return color
        case .dynamic:
            let ratio = totalSegments > 0 ? Double(completedSegments) / Double(totalSegments) : 0
            if ratio <= 0.33 { return .red }
            if ratio <= 0.66 { return .orange }
            return .green
        }
    }

    private func segmentColor(at index: Int) -> Color {
        if index < completedSegments {
            highlightCurrent ? fillColor.opacity(0.4) : fillColor
        } else if index == completedSegments, highlightCurrent {
            fillColor
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
                    .transition(.opacity.combined(with: .scale(scale: 0.7)))
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
        SegmentedProgressBar(totalSegments: 6, completedSegments: Int(completed), fill: .solid(.appAccent))
        SegmentedProgressBar(totalSegments: 6,
                             completedSegments: Int(completed),
                             fill: .solid(.appAccent),
                             highlightCurrent: true)
        Slider(value: $completed, in: 0 ... 6, step: 1)
    }
    .padding()
    .environment(\.font, .app())
}
