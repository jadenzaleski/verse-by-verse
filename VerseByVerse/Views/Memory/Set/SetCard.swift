//
//  SetCard.swift
//  VerseByVerse
//
//  Rewritten to use MeshGradient directly
//

import SwiftUI

struct SetCard: View {
    var title: String
    var passageCount: Int?
    var verseCount: Int?
    var description: String?
    var positionSeed: Int
    var colorShuffleSeed: Int
    var colorPallette: MeshPalette

    init(
        title: String = "The Gospels",
        passageCount: Int? = nil,
        verseCount: Int? = nil,
        description: String? = nil,
        positionSeed: Int = 123,
        colorShuffleSeed: Int = 1234,
        colorPallette: MeshPalette = MeshPalette.all[0],
    ) {
        self.title = title
        self.passageCount = passageCount
        self.verseCount = verseCount
        self.description = description
        self.positionSeed = positionSeed
        self.colorShuffleSeed = colorShuffleSeed
        self.colorPallette = colorPallette
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SetMesh(colorPallette: colorPallette, colorShuffleSeed: colorShuffleSeed, positionSeed: positionSeed)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))

            Group {
                Text(title)
                    .font(.app(.callout, weight: .semibold))
                    .padding(.top, AppSpacing.xs)

                HStack {
                    Text("\(passageCount ?? 0) Passages")
                    Spacer(minLength: 5)
                    Text("\(verseCount ?? 0) Verses")
                }
                .font(.app(.caption))
                .foregroundStyle(.secondary)
            }
            .lineLimit(1)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        let space: CGFloat = 20.0
        let columns = [
            GridItem(.flexible(), spacing: space),
            GridItem(.flexible(), spacing: space),
        ]
        LazyVGrid(
            columns: columns,
            spacing: space,
        ) {
            SetCard(title: "The Gospels", passageCount: 24, verseCount: 120, positionSeed: 1)
            SetCard(title: "Paul's Epistles", passageCount: 13, verseCount: 87, positionSeed: 12)
            SetCard(title: "Psalms of Ascent", description: "Songs of pilgrimage", positionSeed: 3)
            SetCard(title: "Wisdom Literature", positionSeed: 42)
            SetCard(title: "Pentateuch", passageCount: 5, verseCount: 585, positionSeed: 12345)
            SetCard(title: "Major Prophets", passageCount: 5, verseCount: 300, positionSeed: 987)
            SetCard(title: "Minor Prophets", passageCount: 12, verseCount: 150, positionSeed: 654)
            SetCard(title: "Johannine Writings very", positionSeed: 316)
        }
        .padding()
    }
    .environment(\.font, .app())
}
