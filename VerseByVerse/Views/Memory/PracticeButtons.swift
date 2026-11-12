//
//  PracticeButtons.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/11/26.
//

import SwiftUI

/// The detail screens' full-width Practice button, under the Memory Score card.
/// Reports whether it's on screen so ``PracticeToolbar`` can show its own
/// Practice button only once this one has scrolled away.
struct PracticeStartButton: View {
    @Binding var isVisible: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Practice", systemImage: "play.fill")
                .padding(.vertical, AppSpacing.xs)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .onScrollVisibilityChange(threshold: 0.5) { visible in
            withAnimation { isVisible = visible }
        }
    }
}

/// The detail screens' top-right toolbar: Practice, shown only while the
/// full-width ``PracticeStartButton`` is scrolled out of view, and a More
/// menu holding Delete, kept apart from the primary action.
struct PracticeToolbar: ToolbarContent {
    let deleteTitle: String
    /// Whether to show the toolbar's Practice button.
    let showsPractice: Bool
    let onPractice: () -> Void
    let onDelete: () -> Void

    var body: some ToolbarContent {
        if showsPractice {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Practice", systemImage: "play.fill", action: onPractice)
                    .buttonStyle(.glassProminent)
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu("More", systemImage: "ellipsis") {
                Button(deleteTitle, systemImage: "trash", role: .destructive, action: onDelete)
            }
        }
    }
}

#Preview {
    @Previewable @State var isStartVisible = true
    NavigationStack {
        ScrollView {
            PracticeStartButton(isVisible: $isStartVisible) {}
                .padding()
            Color.clear.frame(height: 2000)
        }
        .toolbar {
            PracticeToolbar(
                deleteTitle: "Delete Verse",
                showsPractice: !isStartVisible,
                onPractice: {},
                onDelete: {},
            )
        }
        .navigationTitle("John 3:16")
        .navigationBarTitleDisplayMode(.inline)
    }
    .environment(\.font, .app())
}
