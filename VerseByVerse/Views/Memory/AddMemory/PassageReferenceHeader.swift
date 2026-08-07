//
//  PassageReferenceHeader.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/4/26.
//

import SwiftUI

struct PassageReferenceHeader: View {
    @Environment(BibleStore.self) private var bibleStore
    let reference: String
    let isRefValid: Bool
    let onRefresh: () -> Void

    private var isLoading: Bool {
        bibleStore.state == .loading
    }

    private var disableRefresh: Bool {
        !isRefValid || isLoading
    }

    var body: some View {
        HStack {
            Text(reference.isEmpty ? "Reference" : reference)
                .textCase(.uppercase)
            Spacer()
            Button {
                onRefresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .disabled(disableRefresh)
        }
        .font(.app(.footnote, weight: .semibold))
    }
}
