//
//  SetMemberSwipeRow.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/10/26.
//

import SwiftUI

/// A set member (passage or verse card) that can be swiped, or long-pressed, to
/// remove it from the set after confirmation. The dialog hangs off the card, not
/// the swipe button, which leaves the hierarchy once the row snaps closed, and the
/// button isn't `role: .destructive`, so a full swipe can't remove before confirming.
struct SetMemberSwipeRow<Content: View>: View {
    let title: String
    let message: LocalizedStringKey
    @ViewBuilder let content: Content
    let onRemove: () -> Void

    @State private var confirmingRemove = false

    var body: some View {
        content
            .swipeActions {
                Button {
                    confirmingRemove = true
                } label: {
                    Label("Remove from Set", systemImage: "minus.circle")
                        .labelStyle(.iconOnly)
                }
                .tint(.appDestructive)
            }
            .contextMenu {
                Button(role: .destructive) {
                    confirmingRemove = true
                } label: {
                    Label("Remove from Set", systemImage: "minus.circle")
                }
            }
            .confirmationDialog(
                "Remove \(title) from this set?",
                isPresented: $confirmingRemove,
                titleVisibility: .visible,
            ) {
                Button("Remove from Set", role: .destructive, action: onRemove)
            } message: {
                Text(message)
            }
    }
}
