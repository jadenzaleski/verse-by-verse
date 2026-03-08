//
//  AddPassageView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 3/1/26.
//

import SwiftUI

struct AddPassageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(BibleStore.self) private var bibleStore

    @State private var passageText: String = ""
    @State private var selectedBook = "John"
    @State private var startChapter: String = ""
    @State private var startVerse: String = ""
    @State private var endChapter: String = ""
    @State private var endVerse: String = ""
    @Namespace private var namespace

    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case startChapter, startVerse, endChapter, endVerse }

    @State private var selectedTranslation = "ESV"
    private let translations = ["ESV", "NIV", "KJV", "NASB", "CSB"]
    private let textFieldCornerRadius: CGFloat = 5

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Translation", selection: $selectedTranslation) {
                        ForEach(translations, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    .pickerStyle(.menu)
                    Picker("Book", selection: $selectedBook) {
                        ForEach(bibleStore.bibleBooksOrder, id: \.self) { book in
                            Text(book).tag(book)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack {
                        Text("Ref")
                        Spacer(minLength: 3)
                        TextField("Ch", text: $startChapter)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .frame(width: 50)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: textFieldCornerRadius, style: .continuous)
                                    .fill(Color(.secondarySystemBackground)),
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: textFieldCornerRadius, style: .continuous)
                                    .stroke(focusedField == .startChapter ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: 1),
                            )
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .startChapter)
                            .submitLabel(.next)
                            .onSubmit { focusNext() }
                            .onChange(of: startChapter) { _, newValue in
                                let filtered = newValue.filter(\.isNumber)
                                if filtered != newValue { startChapter = filtered }
                                if startChapter.count > 3 { startChapter = String(startChapter.prefix(3)) }

                                // Validate against BibleStore
                                if let ch = Int(startChapter) {
                                    let maxChapters = bibleStore.chapterCount(for: selectedBook)
                                    if ch > maxChapters { startChapter = String(maxChapters) }
                                }

                                if startChapter.count == 3 { focusNext() }
                            }
                        Text(":")
                        TextField("Vs", text: $startVerse)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .frame(width: 50)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: textFieldCornerRadius, style: .continuous)
                                    .fill(Color(.secondarySystemBackground)),
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: textFieldCornerRadius, style: .continuous)
                                    .stroke(focusedField == .startVerse ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: 1),
                            )
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .startVerse)
                            .submitLabel(.next)
                            .onSubmit { focusNext() }
                            .onChange(of: startVerse) { _, newValue in
                                let filtered = newValue.filter(\.isNumber)
                                if filtered != newValue { startVerse = filtered }
                                if startVerse.count > 3 { startVerse = String(startVerse.prefix(3)) }

                                // Validate against BibleStore
                                if let ch = Int(startChapter), let vs = Int(startVerse) {
                                    let maxVerses = bibleStore.verseCount(for: selectedBook, chapter: ch)
                                    if vs > maxVerses { startVerse = String(maxVerses) }
                                }

                                if startVerse.count == 3 { focusNext() }
                            }
                        Text("-")
                        TextField("Ch", text: $endChapter)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .frame(width: 50)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: textFieldCornerRadius, style: .continuous)
                                    .fill(Color(.secondarySystemBackground)),
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: textFieldCornerRadius, style: .continuous)
                                    .stroke(focusedField == .endChapter ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: 1),
                            )
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .endChapter)
                            .submitLabel(.next)
                            .onSubmit { focusNext() }
                            .onChange(of: endChapter) { _, newValue in
                                let filtered = newValue.filter(\.isNumber)
                                if filtered != newValue { endChapter = filtered }
                                if endChapter.count > 3 { endChapter = String(endChapter.prefix(3)) }

                                // Validate against BibleStore
                                if let ch = Int(endChapter) {
                                    let maxChapters = bibleStore.chapterCount(for: selectedBook)
                                    if ch > maxChapters { endChapter = String(maxChapters) }
                                }

                                if endChapter.count == 3 { focusNext() }
                            }
                        Text(":")
                        TextField("Vs", text: $endVerse)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .frame(width: 50)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: textFieldCornerRadius, style: .continuous)
                                    .fill(Color(.secondarySystemBackground)),
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: textFieldCornerRadius, style: .continuous)
                                    .stroke(focusedField == .endVerse ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: 1),
                            )
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .endVerse)
                            .submitLabel(.done)
                            .onSubmit { focusNext() }
                            .onChange(of: endVerse) { _, newValue in
                                let filtered = newValue.filter(\.isNumber)
                                if filtered != newValue { endVerse = filtered }
                                if endVerse.count > 3 { endVerse = String(endVerse.prefix(3)) }

                                // Validate against BibleStore
                                if let ch = Int(endChapter), let vs = Int(endVerse) {
                                    let maxVerses = bibleStore.verseCount(for: selectedBook, chapter: ch)
                                    if vs > maxVerses { endVerse = String(maxVerses) }
                                }
                            }
                    }

                } footer: {
                    Group {
                        ProgressView()
                        Text(" ")
                    }
                    .font(.app(.footnote))
                }

                Section {
                    Text("For God so loved the World, that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life. John 3:16")
                } header: {
                    Text("PASSAGE")
                        .font(.app(.footnote, weight: .semibold))

                } footer: {
                    Text(" ")
                }
            }
            .navigationTitle("Add Passage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image("lucide.x")
                            .scaleEffect(0.80)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image("lucide.plus")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accent)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if focusedField != nil {
                    keyboardBar()
                }
            }
            .task {
                await bibleStore.loadBibleData()
            }
            .onChange(of: selectedBook) {
                startChapter = ""
                startVerse = ""
                endChapter = ""
                endVerse = ""
            }
        }
    }

    private func focusNext() {
        switch focusedField {
        case .startChapter:
            focusedField = .startVerse
        case .startVerse:
            focusedField = .endChapter
        case .endChapter:
            focusedField = .endVerse
        case .endVerse:
            focusedField = nil
        case .none:
            focusedField = .startChapter
        }
    }

    private func focusPrevious() {
        switch focusedField {
        case .endVerse:
            focusedField = .endChapter
        case .endChapter:
            focusedField = .startVerse
        case .startVerse:
            focusedField = .startChapter
        case .startChapter:
            focusedField = nil
        case .none:
            focusedField = nil
        }
    }

    private var currentFieldLimits: (min: Int, max: Int) {
        let maxChapters = bibleStore.chapterCount(for: selectedBook)

        switch focusedField {
        case .startChapter:
            let max = Int(endChapter) ?? maxChapters
            return (1, max)

        case .startVerse:
            let ch = Int(startChapter) ?? 1
            let bookVsMax = bibleStore.verseCount(for: selectedBook, chapter: ch)
            // If start and end chapters are the same, limit startVerse by endVerse
            if let endChVal = Int(endChapter), ch == endChVal, let endVsVal = Int(endVerse) {
                return (1, endVsVal)
            }
            return (1, bookVsMax)

        case .endChapter:
            let min = Int(startChapter) ?? 1
            return (min, maxChapters)

        case .endVerse:
            let ch = Int(endChapter) ?? 1
            let bookVsMax = bibleStore.verseCount(for: selectedBook, chapter: ch)
            // If end and start chapters are the same, limit endVerse by startVerse
            if let startChVal = Int(startChapter), ch == startChVal, let startVsVal = Int(startVerse) {
                return (startVsVal, bookVsMax)
            }
            return (1, bookVsMax)

        case .none:
            return (1, 1)
        }
    }

    private func setFieldValue(_ value: Int) {
        let stringValue = String(value)
        switch focusedField {
        case .startChapter: startChapter = stringValue
        case .startVerse: startVerse = stringValue
        case .endChapter: endChapter = stringValue
        case .endVerse: endVerse = stringValue
        case .none: break
        }

        // Auto-advance to next field
        focusNext()
    }

    func keyboardBar() -> some View {
        let limits = currentFieldLimits
        return HStack {
            GlassEffectContainer {
                HStack {
                    Button {
                        focusPrevious()
                    } label: {
                        Image("lucide.chevron.left")
                            .frame(width: 20, height: 20)
                            .padding()
                            .glassEffect(.regular.interactive())
                            .glassEffectUnion(id: 1, namespace: namespace)
                    }

                    Button {
                        focusNext()
                    } label: {
                        Image("lucide.chevron.left")
                            .rotationEffect(.degrees(180))
                            .frame(width: 20, height: 20)
                            .padding()
                            .glassEffect(.regular.interactive())
                            .glassEffectUnion(id: 1, namespace: namespace)
                    }
                }
            }

            Spacer()

            GlassEffectContainer {
                HStack {
                    Button {
                        setFieldValue(limits.min)
                    } label: {
                        Text("\(limits.min)")
                            .padding()
                            .padding(.leading, 10)
                            .glassEffect(.regular.interactive())
                            .glassEffectUnion(id: 2, namespace: namespace)
                    }

                    Divider()
                        .frame(width: 1, height: 20)
                        .overlay(.separator)
                        .glassEffect()
                        .glassEffectUnion(id: 2, namespace: namespace)

                    Button {
                        setFieldValue(limits.max)
                    } label: {
                        Text("\(limits.max)")
                            .padding()
                            .padding(.trailing, 10)
                            .glassEffect(.regular.interactive())
                            .glassEffectUnion(id: 2, namespace: namespace)
                    }
                }
            }

            Button {
                withAnimation {
                    focusedField = nil
                }
            } label: {
                Image("lucide.check")
                    .frame(width: 20, height: 20)
                    .padding()
                    .glassEffect(.regular.interactive())
                    .glassEffectUnion(id: 3, namespace: namespace)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    AddPassageView()
        .environment(\.font, .app())
        .environment(BibleStore.shared)
}
