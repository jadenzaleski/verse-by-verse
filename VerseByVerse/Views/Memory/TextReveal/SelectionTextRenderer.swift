//
//  SelectionTextRenderer.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/11/26.
//

import SwiftUI

/// Draws a selection's text for the card's two animations, Show/Hide (typing
/// the hidden lines in) and the missed-word heatmap (spreading the lines and
/// drawing the color on). The timing rules live in ``TextRevealMotion``; this
/// type only draws a given ``TextRevealState``, which SwiftUI interpolates
/// through ``animatableData``.
///
/// The text is laid out once at its natural width, so words never re-wrap
/// mid-animation; untyped glyphs simply aren't drawn, so nothing is clipped.
struct SelectionTextRenderer: TextRenderer {
    var state: TextRevealState
    var collapsedLines: Int
    var heatmap: HeatmapData?

    var animatableData: AnimatablePair<Double, Double> {
        get { state.animatableData }
        set { state.animatableData = newValue }
    }

    func sizeThatFits(proposal: ProposedViewSize, text: TextProxy) -> CGSize {
        let size = text.sizeThatFits(proposal)
        return CGSize(width: size.width, height: size.height * (1 + TextRevealMotion.heatStretch * state.spread))
    }

    func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
        let lines = Array(layout)
        guard !lines.isEmpty else { return }

        let naturalHeight = lines.map(\.typographicBounds.rect.maxY).max() ?? 0
        let gap = TextRevealMotion.heatStretch * naturalHeight / Double(lines.count)
        let firstCharacter = layout.first?.first?.first?.characterIndices.first
        let reveal = state.reveal
        let spread = state.spread
        let pen = state.pen

        for (index, line) in lines.enumerated() {
            let typed = TextRevealMotion.typed(
                line: index, collapsedLines: collapsedLines, lineCount: lines.count, reveal: reveal,
            )
            guard typed > 0 else { continue }
            let glyphCount = line.reduce(0) { $0 + $1.count }
            let typedGlyphs = typed >= 1 ? glyphCount : Int((typed * Double(glyphCount)).rounded(.up))

            var lineContext = ctx
            lineContext.translateBy(x: 0, y: spread * gap * Double(index + 1))

            if state.heat > 0, let heatmap, let firstCharacter {
                let paint = TextRevealMotion.painted(line: index, lineCount: lines.count, pen: pen)
                drawWords(
                    of: line, typedGlyphs: typedGlyphs, paint: paint, in: &lineContext,
                    heatmap: heatmap, firstCharacter: firstCharacter,
                )
            } else if typedGlyphs >= glyphCount {
                lineContext.draw(line)
            } else {
                var drawn = 0
                for run in line {
                    for slice in run where drawn < typedGlyphs {
                        lineContext.draw(slice)
                        drawn += 1
                    }
                }
            }
        }
    }

    // MARK: - Heatmap

    private struct WordRun {
        var token: HeatmapToken
        var slices: [Text.Layout.RunSlice]
        var rect: CGRect
    }

    /// The typed glyphs of `line`, grouped into words; glyphs that belong to no
    /// word (spaces) come back separately.
    private func wordRuns(
        in line: Text.Layout.Line,
        typedGlyphs: Int,
        heatmap: HeatmapData,
        firstCharacter: Text.Layout.CharacterIndex,
    ) -> (words: [WordRun], loose: [Text.Layout.RunSlice]) {
        var words: [WordRun] = []
        var loose: [Text.Layout.RunSlice] = []
        let slices = line.flatMap(\.self).prefix(typedGlyphs)
        for slice in slices {
            let token = slice.characterIndices.first.flatMap {
                heatmap.token(atCharacter: firstCharacter.distance(to: $0))
            }
            guard let token else {
                loose.append(slice)
                continue
            }
            let rect = slice.typographicBounds.rect
            if let last = words.last, last.token.id == token.id {
                words[words.count - 1].slices.append(slice)
                words[words.count - 1].rect = last.rect.union(rect)
            } else {
                words.append(WordRun(token: token, slices: [slice], rect: rect))
            }
        }
        return (words, loose)
    }

    /// Draws a line word by word, tinting each and putting its miss count above it.
    private func drawWords(
        of line: Text.Layout.Line,
        typedGlyphs: Int,
        paint: Double,
        in context: inout GraphicsContext,
        heatmap: HeatmapData,
        firstCharacter: Text.Layout.CharacterIndex,
    ) {
        let (words, loose) = wordRuns(
            in: line, typedGlyphs: typedGlyphs, heatmap: heatmap, firstCharacter: firstCharacter,
        )

        for slice in loose {
            context.draw(slice)
        }

        let lineTop = line.typographicBounds.rect.minY
        // A pen sweeps left to right; everything behind it is colored.
        let bounds = line.typographicBounds.rect
        let pen = bounds.minX + bounds.width * paint
        for word in words {
            let tint = tint(for: word.token, heatmap: heatmap)
            let painted = word.rect.insetBy(dx: -2, dy: -2)
            let covered = CGRect(x: painted.minX, y: painted.minY,
                                 width: min(max(pen - painted.minX, 0), painted.width), height: painted.height)

            if let tint, covered.width > 0 {
                context.drawLayer { layer in
                    for slice in word.slices {
                        layer.draw(slice)
                    }
                    layer.blendMode = .sourceAtop
                    layer.fill(Path(covered), with: .color(tint))
                }
            } else {
                for slice in word.slices {
                    context.draw(slice)
                }
            }

            // The count lands once the pen reaches the middle of its word.
            if let tint, word.token.misses > 0, pen >= word.rect.midX {
                drawCount(word.token.misses, tint: tint, above: CGPoint(x: word.rect.midX, y: lineTop), in: &context)
            }
        }
    }

    private func drawCount(_ count: Int, tint: Color, above point: CGPoint, in context: inout GraphicsContext) {
        let label = context.resolve(
            Text("\(count)").font(.bible(.caption2, weight: .semibold)).foregroundStyle(tint),
        )
        context.draw(label, at: point, anchor: .bottom)
    }

    private func tint(for token: HeatmapToken, heatmap: HeatmapData) -> Color? {
        guard token.kind == .word, token.hasHistory else { return nil }
        return WordHeatmap.color(misses: token.misses, maxMisses: heatmap.maxMisses)
    }
}

#Preview("Reveal 0 / 0.5 / 1") {
    let passage = PreviewData.samplePassage
    let selection = PreviewData.bibleStore.selections[passage.selectionKey]
    return VStack(alignment: .leading, spacing: AppSpacing.xl) {
        if let selection {
            ForEach([0.0, 0.5, 1.0], id: \.self) { reveal in
                selection.annotatedText
                    .textRenderer(SelectionTextRenderer(
                        state: TextRevealState(expansion: reveal, heat: 0),
                        collapsedLines: 3,
                    ))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .border(.quaternary)
            }
        }
    }
    .padding()
}
