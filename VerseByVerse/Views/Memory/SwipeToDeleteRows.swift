//
//  SwipeToDeleteRows.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/23/26.
//

import SwiftUI

// Memory-list rows with a swipe-to-delete action that asks for confirmation in
// an action sheet. The sheet is attached to the whole card rather than the swipe
// button, because the button leaves the view hierarchy as soon as the row snaps
// closed; with the card as its source, the sheet presents above or below it.
// The action itself is not `role: .destructive`, which would remove the row on a
// full swipe before the user has confirmed.

/// A passage card that can be swiped to delete.
struct PassageSwipeRow: View {
    let passage: Passage
    /// Called after confirmation; the flag says whether its verses go too.
    let onDelete: (_ alsoDeleteVerses: Bool) -> Void

    @State private var confirmingDelete = false

    var body: some View {
        NavigationLink(destination: PassageDetailView(passage: passage)) {
            PassageCard(passage: passage)
        }
        .buttonStyle(.plain)
        .swipeActions {
            SwipeDeleteButton { confirmingDelete = true }
        }
        .confirmationDialog("Delete \(passage.reference)?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete Passage", role: .destructive) {
                onDelete(false)
            }
            Button("Delete Passage & Verses", role: .destructive) {
                onDelete(true)
            }
        } message: {
            Text(Passage.deleteConfirmationMessage)
        }
    }
}

/// A verse card that can be swiped to delete.
struct VerseSwipeRow: View {
    let verse: Verse
    let onDelete: () -> Void

    @State private var confirmingDelete = false

    var body: some View {
        NavigationLink(destination: VerseDetailView(verse: verse)) {
            VerseCard(verse: verse)
        }
        .buttonStyle(.plain)
        .swipeActions {
            SwipeDeleteButton { confirmingDelete = true }
        }
        .confirmationDialog("Delete \(verse.reference)?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button(verse.deleteConfirmationLabel, role: .destructive) {
                onDelete()
            }
        } message: {
            Text(verse.deleteConfirmationMessage)
        }
    }
}

private struct SwipeDeleteButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Delete", systemImage: "trash")
                .labelStyle(.iconOnly)
        }
        .tint(.appDestructive)
    }
}
