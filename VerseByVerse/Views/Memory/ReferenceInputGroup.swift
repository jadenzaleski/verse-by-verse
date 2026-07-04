//
//  ReferenceInputGroup.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/4/26.
//

import SwiftUI

struct ReferenceInputGroup: View {
    @Environment(BibleStore.self) private var bibleStore

    let selectedBook: String
    @Binding var startChapter: String
    @Binding var startVerse: String
    @Binding var endChapter: String
    @Binding var endVerse: String
    @FocusState.Binding var focusedField: AddPassageView.Field?
    let onAdvance: () -> Void

    init(
        selectedBook: String,
        startChapter: Binding<String>,
        startVerse: Binding<String>,
        endChapter: Binding<String>,
        endVerse: Binding<String>,
        focusedField: FocusState<AddPassageView.Field?>.Binding,
        onAdvance: @escaping () -> Void,
    ) {
        self.selectedBook = selectedBook
        _startChapter = startChapter
        _startVerse = startVerse
        _endChapter = endChapter
        _endVerse = endVerse
        _focusedField = focusedField
        self.onAdvance = onAdvance
    }

    var body: some View {
        HStack {
            Text("Ref")
            Spacer(minLength: 3)
            NumericRefTextField(
                placeholder: "Ch",
                text: $startChapter,
                isFocused: focusedField == .startChapter,
                focus: $focusedField,
                thisField: .startChapter,
                submitLabel: .next,
                width: 50,
            ) {
                onAdvance()
            } onChange: { newValue in
                var value = newValue.filter(\.isNumber)
                if value.count > 3 { value = String(value.prefix(3)) }
                if let chapter = Int(value) {
                    let max = bibleStore.chapterCount(for: selectedBook)
                    if chapter > max { value = String(max) }
                }
                startChapter = value
            }
            Text(":")
            NumericRefTextField(
                placeholder: "Vs",
                text: $startVerse,
                isFocused: focusedField == .startVerse,
                focus: $focusedField,
                thisField: .startVerse,
                submitLabel: .next,
                width: 50,
            ) {
                onAdvance()
            } onChange: { newValue in
                var value = newValue.filter(\.isNumber)
                if value.count > 3 { value = String(value.prefix(3)) }
                if let chapter = Int(startChapter), let verse = Int(value) {
                    let max = bibleStore.verseCount(for: selectedBook, chapter: chapter)
                    if verse > max { value = String(max) }
                }
                startVerse = value
            }
            Text("–")
            NumericRefTextField(
                placeholder: "Ch",
                text: $endChapter,
                isFocused: focusedField == .endChapter,
                focus: $focusedField,
                thisField: .endChapter,
                submitLabel: .next,
                width: 50,
            ) {
                onAdvance()
            } onChange: { newValue in
                var value = newValue.filter(\.isNumber)
                if value.count > 3 { value = String(value.prefix(3)) }
                if let chapter = Int(value) {
                    let max = bibleStore.chapterCount(for: selectedBook)
                    if chapter > max { value = String(max) }
                }
                endChapter = value
            }
            Text(":")
            NumericRefTextField(
                placeholder: "Vs",
                text: $endVerse,
                isFocused: focusedField == .endVerse,
                focus: $focusedField,
                thisField: .endVerse,
                submitLabel: .done,
                width: 50,
            ) {
                onAdvance()
            } onChange: { newValue in
                var value = newValue.filter(\.isNumber)
                if value.count > 3 { value = String(value.prefix(3)) }
                if let chapter = Int(endChapter.isEmpty ? startChapter : endChapter),
                   let verse = Int(value)
                {
                    let max = bibleStore.verseCount(for: selectedBook, chapter: chapter)
                    if verse > max { value = String(max) }
                }
                endVerse = value
            }
        }
    }
}
