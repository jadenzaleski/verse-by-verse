//
//  PassagePickers.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/4/26.
//

import SwiftUI

struct PassagePickers: View {
    @Environment(BibleStore.self) private var bibleStore
    @Binding var selectedTranslation: String
    @Binding var selectedBook: String

    var body: some View {
        Picker("Translation", selection: $selectedTranslation) {
            if let available = bibleStore.availableTranslations, !available.isEmpty {
                ForEach(available, id: \.abbreviation) { translation in
                    Text(translation.abbreviation).tag(translation.abbreviation)
                }
                // Ensure the current selection is always a valid tag to avoid Picker warnings
                if !available.contains(where: { $0.abbreviation == selectedTranslation }) {
                    Text(selectedTranslation).tag(selectedTranslation)
                }
            } else {
                // While loading or if list is empty, ensure the selection has a tag
                Text(selectedTranslation).tag(selectedTranslation)
            }
        }
        .pickerStyle(.menu)
        Picker("Book", selection: $selectedBook) {
            ForEach(bibleStore.bibleBooksOrder, id: \.self) { book in
                Text(book).tag(book)
            }
        }
        .pickerStyle(.menu)
    }
}
