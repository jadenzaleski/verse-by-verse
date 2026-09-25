//
//  LongTextCard.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/13/26.
//

import SwiftUI
import UIKit

/// A text card that collapses long text and reveals a Show/Hide toggle only
/// when the text overflows. The visible `Text` is laid out once at full size
/// (`fixedSize`) and only a clip window's height is animated over it, so words
/// never re-wrap mid-animation — expanding just uncovers more of it.
struct LongTextCard: View {
    let title: String
    let translation: BibleTranslationInfo
    let text: Text

    @Environment(\.dismiss) private var dismiss
    @State private var isExpanded = false
    @State private var fullHeight: CGFloat = 0
    @State private var collapsedHeight: CGFloat = 0
    @State private var isShowingCopyright: Bool = false

    /// Collapsed cap, in lines so it adapts to Dynamic Type.
    private let collapsedLineLimit = 5

    private var isTruncated: Bool {
        fullHeight > collapsedHeight + 1
    }

    /// Clip-window height: `nil` (natural, no clip) until measured or when the
    /// text fits; otherwise concrete so the frame animates between two known
    /// values rather than toward an un-interpolatable `nil`/`.infinity`.
    private var clipHeight: CGFloat? {
        guard isTruncated, fullHeight > 0, collapsedHeight > 0 else { return nil }
        return isExpanded ? fullHeight : collapsedHeight
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
        .animation(.smooth(duration: 0.3), value: isExpanded)
        .sheet(isPresented: $isShowingCopyright, onDismiss: {}) {
            CopyrightSheetView(translation: translation)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            Text(title)
                .font(.app(.title2))
            Spacer()
            Button {
                isShowingCopyright = true
            } label: {
                Text(translation.abbreviation)
                    .font(.app(.caption, weight: .semibold))
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(Color.secondary.opacity(0.15), in: Capsule())
                    .foregroundStyle(.secondary)
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var textContent: some View {
        text
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: clipHeight, alignment: .top)
            .clipped()
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
            Text("\(Image(systemName: isExpanded ? "chevron.up" : "chevron.down"))  \(isExpanded ? "Hide" : "Show")")
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
            if index > 0 { result += AttributedString(" ") }
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
        translation: BibleTranslationInfo(id: "KJV", abbreviation: "KJV", name: "King James Version", copyright: "Public Domain", provider: "Public Domain"),
        text: Text(attributed),
    )
    .padding()
    .environment(\.font, .bible())
}
