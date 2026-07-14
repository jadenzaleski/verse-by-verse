//
//  LongTextCard.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/13/26.
//

import SwiftUI

/// A text card that clamps to n lines and only reveals a Show/Hide toggle
/// when the text actually overflows that limit. Truncation is detected by
/// comparing two hidden measurement renders (full height vs. n-line height)
/// against each other rather than guessing from character count, since line
/// count depends on the device width and Dynamic Type size.
struct LongTextCard: View {
    let title: String
    let translation: String
    let text: String

    @State private var isExpanded = false
    @State private var fullHeight: CGFloat = 0
    @State private var clampedHeight: CGFloat = 0

    private let collapsedLineLimit = 5

    private var isTruncated: Bool {
        fullHeight > clampedHeight + 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            header
            textContent
            if isTruncated {
                toggleButton
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        // Animating only `textContent`'s own frame left the toggle button's
        // reposition (a sibling layout effect, not that view's own size)
        // outside the transaction — it snapped to its final spot instantly
        // while the text was still easing, producing a double-image ghost.
        // One animation on the whole card keeps both in the same beat.
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private var header: some View {
        HStack {
            Text(title)
                .font(.app(.title2))
            Spacer()
            Text(translation)
                .font(.app(.caption, weight: .semibold))
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(Color.secondary.opacity(0.15), in: Capsule())
                .foregroundStyle(.secondary)
        }
    }

    /// The visible text is never line-limited — `lineLimit` changes can't
    /// animate (there's no interpolation between two line counts), so
    /// instead the *height* is clamped via `.frame` + `.clipped()`, which
    /// SwiftUI animates natively. Trade-off: the collapsed edge is a hard
    /// clip rather than lineLimit's "…" ellipsis.
    private var textContent: some View {
        Text(text)
            .font(.app(.body))
            // Both endpoints must be concrete, already-measured values —
            // animating toward `.infinity` has no interpolation path, so
            // SwiftUI can't ease it and just snaps instead.
            .frame(maxHeight: isExpanded ? fullHeight : clampedHeight, alignment: .top)
            .clipped()
            .background(
                // Same width, no limit — its natural height is the "fully
                // expanded" measurement. A `.background` never grows the
                // parent's own reported size, so this can't affect layout.
                Text(text)
                    .font(.app(.body))
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                    .onGeometryChange(for: CGFloat.self, of: { $0.size.height }, action: { fullHeight = $0 }),
            )
            .background(
                // Always clamped to 5 lines regardless of `isExpanded`, so
                // this stays a stable baseline to compare against even
                // after the visible text expands, and is the collapsed
                // height target for the frame animation above.
                Text(text)
                    .font(.app(.body))
                    .lineLimit(collapsedLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                    .onGeometryChange(for: CGFloat.self, of: { $0.size.height }, action: { clampedHeight = $0 }),
            )
    }

    private var toggleButton: some View {
        Button {
            isExpanded.toggle()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                // One glyph that rotates 180° rather than swapping between
                // "chevron.up"/"chevron.down" — a discrete symbol swap can't
                // interpolate, so it just double-exposes both icons for a
                // frame; a rotation is a single continuous value to animate.
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                Text(isExpanded ? "Hide" : "Show")
                    .contentTransition(.opacity)
            }
            .font(.app(.subheadline, weight: .semibold))
            .foregroundStyle(Color.appAccent)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Long Text") {
    LongTextCard(
        title: "Passage",
        translation: "KJV",
        text: String(repeating: "For God so loved the world that he gave his only begotten Son. ", count: 8),
    )
    .padding()
    .environment(\.font, .app())
}

#Preview("Short Text") {
    LongTextCard(
        title: "Verse",
        translation: "KJV",
        text: "For God so loved the world, that he gave his only begotten Son.",
    )
    .padding()
    .environment(\.font, .app())
}
