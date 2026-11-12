//
//  LongTextCard.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/13/26.
//

import SwiftUI
import UIKit

/// A text card that collapses long text and reveals a Show/Hide toggle only
/// when the text overflows, with an optional missed-word heatmap. The text is
/// drawn by ``SelectionTextRenderer`` inside a ``RevealWindow``; both take the
/// same ``TextRevealState`` and follow ``TextRevealMotion``. Hidden probes
/// measure the full and collapsed heights.
struct LongTextCard: View {
    let title: String
    let translation: BibleTranslationInfo
    let text: Text
    /// Shows a "Try Again" button under the text when set (a failed fetch).
    var onRetry: (() -> Void)?
    /// When set, a button beside the translation turns the text into a
    /// missed-word heatmap.
    var heatmap: HeatmapData?

    @State private var isExpanded = false
    @State private var showsHeatmap = false
    @State private var fullHeight: CGFloat = 0
    @State private var collapsedHeight: CGFloat = 0

    /// Collapsed cap, in lines so it adapts to Dynamic Type.
    private let collapsedLineLimit = 5

    private var isTruncated: Bool {
        fullHeight > collapsedHeight + 1
    }

    /// Lines past the collapsed limit, from the measured heights.
    private var hiddenLines: Double {
        TextRevealMotion.hiddenLines(
            fullHeight: fullHeight, collapsedHeight: collapsedHeight, collapsedLines: collapsedLineLimit,
        )
    }

    private var revealState: TextRevealState {
        TextRevealState(isExpanded: isExpanded, showsHeatmap: showsHeatmap)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            header
            textContent
            if let heatmap, showsHeatmap {
                HeatmapLegend(data: heatmap)
                    .transition(.opacity.combined(with: .offset(y: -6)))
            }
            if let onRetry {
                Button("Try Again", action: onRetry)
                    .font(.app(.subheadline, weight: .semibold))
            }
            if isTruncated, !showsHeatmap {
                toggleButton
                    // Leaves at once with the heatmap; returns once the text has settled.
                    .transition(.asymmetric(
                        insertion: .opacity.animation(TextRevealMotion.toggleReturnAnimation),
                        removal: .identity,
                    ))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
//        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        .animation(TextRevealMotion.revealAnimation(hiddenLines: hiddenLines), value: isExpanded)
        .animation(TextRevealMotion.heatAnimation, value: showsHeatmap)
    }

    private var header: some View {
        HStack {
            Text(title)
                .font(.app(.title2))
            Spacer()
            TranslationBadgeButton(translation: translation)
            if heatmap != nil {
                heatmapButton
            }
        }
    }

    private var heatmapButton: some View {
        Button {
            showsHeatmap.toggle()
        } label: {
            Image(systemName: "square.grid.3x3.fill")
                .foregroundStyle(showsHeatmap ? Color.appAccent : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Missed words heatmap")
        .accessibilityAddTraits(showsHeatmap ? .isSelected : [])
    }

    private var textContent: some View {
        text
            .textRenderer(SelectionTextRenderer(
                state: revealState, collapsedLines: collapsedLineLimit, heatmap: heatmap,
            ))
            .accessibilityValue(showsHeatmap ? (heatmap?.accessibilitySummary ?? "") : "")
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(RevealWindow(
                state: revealState,
                collapsedHeight: collapsedHeight,
                fullHeight: fullHeight,
                hiddenLines: hiddenLines,
            ))
            .background(heightProbes)
    }

    /// Hidden copies that report the full and collapsed heights at the live
    /// width/Dynamic Type without affecting the visible layout.
    private var heightProbes: some View {
        ZStack {
            text
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }, action: { fullHeight = $0 })
            text
                .lineLimit(collapsedLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }, action: { collapsedHeight = $0 })
        }
        .hidden()
    }

    private var toggleButton: some View {
        Button {
            isExpanded.toggle()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                // One chevron that turns over, rather than two that swap.
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                Text(isExpanded ? "Hide" : "Show")
            }
            .font(.app(.subheadline, weight: .semibold))
            .foregroundStyle(Color.appAccent)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Long Text") {
    let attributed: AttributedString = {
        var result = AttributedString()
        for (index, number) in (1 ... 8).enumerated() {
            if index > 0 {
                result += AttributedString(" ")
            }
            var num = AttributedString("\(number)")
            num.swiftUI.font = .bible(.caption2)
            num.swiftUI.foregroundColor = Color.secondary
            num.uiKit.baselineOffset = UIFontMetrics(forTextStyle: .caption2).scaledValue(for: 5)
            result += num
            result += AttributedString(" For God so loved the world that he gave his only begotten Son.")
        }
        return result
    }()
    LongTextCard(
        title: "Passage",
        translation: BibleTranslationInfo(id: "KJV",
                                          abbreviation: "KJV",
                                          name: "King James Version",
                                          copyright: "Public Domain",
                                          provider: "Public Domain"),
        text: Text(attributed),
    )
    .padding()
    .environment(\.font, .bible())
}

#Preview("Short Text") {
    let attributed: AttributedString = {
        var num = AttributedString("16")
        num.swiftUI.font = .bible(.caption2)
        num.swiftUI.foregroundColor = Color.secondary
        num.uiKit.baselineOffset = UIFontMetrics(forTextStyle: .caption2).scaledValue(for: 5)
        return num + AttributedString(" For God so loved the world, that he gave his only begotten Son.")
    }()
    LongTextCard(
        title: "Verse",
        translation: BibleTranslationInfo(
            id: "KJV",
            abbreviation: "KJV",
            name: "King James Version",
            copyright: "Public Domain",
            provider: "Public Domain",
        ),
        text: Text(attributed),
    )
    .padding()
    .environment(\.font, .bible())
}
