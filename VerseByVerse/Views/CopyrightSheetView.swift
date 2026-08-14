//
//  CopyrightSheetView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 8/9/26.
//

import SwiftUI

struct CopyrightSheetView: View {
    let translation: BibleTranslationInfo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(translation.name)
                    .font(.app(.title))
                Text(translation.abbreviation)
                    .font(.app(.headline))
                    .foregroundStyle(.secondary)

                translation.copyrightText
                    .font(.app(.subheadline))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview("Plain") {
    CopyrightSheetView(
        translation: BibleTranslationInfo(id: "1",
                                          abbreviation: "ABC",
                                          name: "Name",
                                          copyright: "copyright",
                                          provider: "Jaden"),
    )
    .environment(\.font, .app())
}

#Preview("With Markdown Link") {
    CopyrightSheetView(
        translation: BibleTranslationInfo(
            id: "kjv",
            abbreviation: "KJV",
            name: "King James Version",
            copyright: "Public Domain except in the United Kingdom, where a Crown Copyright applies to "
                + "printing the KJV. See the [Queen's Printers Patent]"
                + "(http://www.cambridge.org/about-us/who-we-are/queens-printers-patent).",
            provider: "local",
        ),
    )
    .environment(\.font, .app())
}
