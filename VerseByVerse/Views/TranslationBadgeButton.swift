//
//  TranslationBadgeButton.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/5/26.
//

import SwiftUI

/// The translation's abbreviation in a capsule with an info icon. Tapping
/// either shows the translation's copyright sheet. Shared by the verse text
/// card and the practice activities so the licence notice is always one tap away.
struct TranslationBadgeButton: View {
    let translation: BibleTranslationInfo

    @State private var isShowingCopyright = false

    var body: some View {
        Button {
            isShowingCopyright = true
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Text(translation.abbreviation)
                    .font(.app(.caption, weight: .semibold))
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(Color.secondary.opacity(0.15), in: Capsule())
                Image(systemName: "info.circle")
            }
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(translation.abbreviation) copyright information")
        .sheet(isPresented: $isShowingCopyright) {
            CopyrightSheetView(translation: translation)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    TranslationBadgeButton(
        translation: BibleTranslationInfo(
            id: "kjv", abbreviation: "KJV", name: "King James Version",
            copyright: "Public Domain.", provider: "local",
        ),
    )
    .environment(\.font, .app())
}
