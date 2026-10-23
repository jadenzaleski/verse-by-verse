//
//  Deletion.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/20/26.
//

import Foundation
import SwiftData

// Destructive operations on the library, shared by every screen that offers
// them. None of these save: the context's undo manager can only reverse
// changes made since the last `save()`, so persistence is deferred to the
// app's commit points (scene leaving the foreground) and SwiftData autosave.
// Callers must not follow these with `modelContext.save()`.

extension Passage {
    static let deleteConfirmationMessage =
        "Delete Passage keeps its verses; Delete Passage & Verses also removes the verses."

    /// Deletes this passage. Its verses are kept as standalone cards when
    /// `alsoDeleteVerses` is false; otherwise any verse nothing else
    /// references is swept away along with its reviews.
    func delete(alsoDeleteVerses: Bool, in context: ModelContext) throws {
        if !alsoDeleteVerses {
            for verse in verses ?? [] {
                verse.addedDirectly = true
            }
        }
        context.delete(self)
        try Verse.sweepOrphans(in: context)
        context.undoManager?.setActionName(alsoDeleteVerses ? "Delete Passage & Verses" : "Delete Passage")
    }
}

extension Verse {
    /// Confirm-button title for ``deleteFromLibrary(in:)``: deleting a verse
    /// that belongs to a passage deletes the passage too.
    var deleteConfirmationLabel: String {
        (passages ?? []).isEmpty ? "Delete" : "Delete Passage & Verses"
    }

    var deleteConfirmationMessage: String {
        let owningPassages = passages ?? []
        let message = if owningPassages.isEmpty {
            "This verse will be removed from any sets and deleted."
        } else if owningPassages.count == 1 {
            "This will delete \(owningPassages[0].reference) and all its verses."
        } else {
            "This will delete \(owningPassages.count) passages and all their verses."
        }
        return message
    }

    /// Deletes this verse from the library: removes it from every set, deletes
    /// every passage it belongs to (and so their sibling verses, unless
    /// referenced elsewhere), and sweeps what's left unreferenced.
    func deleteFromLibrary(in context: ModelContext) throws {
        for set in studySets ?? [] {
            set.verses?.removeAll { $0 === self }
            set.modifiedAt = .now
        }
        for passage in passages ?? [] {
            context.delete(passage)
        }
        addedDirectly = false
        try Verse.sweepOrphans(in: context)
        context.undoManager?.setActionName("Delete Verse")
    }
}

extension StudySet {
    /// Deletes this set. Its passages and verses stay in the library, except
    /// verses that were only reachable through the set.
    func delete(in context: ModelContext) throws {
        context.delete(self)
        try Verse.sweepOrphans(in: context)
        context.undoManager?.setActionName("Delete Set")
    }
}
