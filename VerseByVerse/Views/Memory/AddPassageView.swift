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

    @State private var selectedTranslation = "ESV"
    @State private var passageText: String = ""
    @State private var selectedBook = "John"
    @State private var startChapter: String = ""
    @State private var startVerse: String = ""
    @State private var endChapter: String = ""
    @State private var endVerse: String = ""

    @Namespace private var namespace

    @FocusState private var focusedField: Field?

    private enum Field: Hashable { case startChapter, startVerse, endChapter, endVerse }
    private let translations = ["ESV", "NIV", "KJV", "NASB", "CSB"]
    private let textFieldCornerRadius: CGFloat = 5

    private var reference: String {
        guard !startChapter.isEmpty, !startVerse.isEmpty else {
            return ""
        }

        // Same chapter range like John 3:16-18
        if endChapter.isEmpty || endChapter == startChapter {
            if endVerse.isEmpty {
                return "\(selectedBook) \(startChapter):\(startVerse)"
            } else {
                return "\(selectedBook) \(startChapter):\(startVerse)-\(endVerse)"
            }
        }

        // Cross-chapter range like John 3:16-4:2
        if !endChapter.isEmpty {
            if endVerse.isEmpty {
                return "\(selectedBook) \(startChapter):\(startVerse)-\(endChapter)"
            } else {
                return "\(selectedBook) \(startChapter):\(startVerse)-\(endChapter):\(endVerse)"
            }
        }

        return "\(selectedBook) \(startChapter):\(startVerse)"
    }

    private var isRefValid: Bool {
        guard let startChapterInt = Int(startChapter), let startVerseInt = Int(startVerse) else { return false }

        // Basic range check (already force-corrected in onChange, but good for safety)
        guard bibleStore.isValidChapter(startChapterInt, for: selectedBook),
              bibleStore.isValidVerse(startVerseInt, for: selectedBook, chapter: startChapterInt) else { return false }

        // If end is provided, it must be logically after start
        if !endChapter.isEmpty || !endVerse.isEmpty {
            let endCh = Int(endChapter) ?? startChapterInt
            let endVs = Int(endVerse) ?? 0 // If no verse, we assume the whole chapter or it's invalid

            if endCh < startChapterInt { return false }
            if endCh == startChapterInt, !endVerse.isEmpty, endVs < startVerseInt { return false }

            // Validate end range
            if !bibleStore.isValidChapter(endCh, for: selectedBook) { return false }
            if !endVerse.isEmpty, !bibleStore.isValidVerse(endVs, for: selectedBook, chapter: endCh) { return false }
        }

        return true
    }

    private var currentFieldLimits: (min: Int, max: Int) {
        let maxChapters = bibleStore.chapterCount(for: selectedBook)

        switch focusedField {
        case .startChapter:
            return (1, maxChapters)

        case .startVerse:
            let chapter = Int(startChapter) ?? 1
            let bookVsMax = bibleStore.verseCount(for: selectedBook, chapter: chapter)
            return (1, bookVsMax)

        case .endChapter:
            let min = Int(startChapter) ?? 1
            return (min, maxChapters)

        case .endVerse:
            let chapter = Int(endChapter.isEmpty ? startChapter : endChapter) ?? 1
            let bookVsMax = bibleStore.verseCount(for: selectedBook, chapter: chapter)
            if let startChVal = Int(startChapter),
               let startVsVal = Int(startVerse),
               let endChVal = Int(endChapter.isEmpty ? startChapter : endChapter),
               startChVal == endChVal
            {
                return (startVsVal, bookVsMax)
            }
            return (1, bookVsMax)

        case .none:
            return (1, 1)
        }
    }

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
                                    .stroke(
                                        focusedField == .startChapter ? Color.accentColor.opacity(0.8)
                                            : Color.secondary.opacity(0.2),
                                        lineWidth: 1.5,
                                    ),
                            )
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .startChapter)
                            .submitLabel(.next)
                            .onSubmit { focusNext() }
                            .onChange(of: startChapter) { _, newValue in
                                let filtered = newValue.filter(\.isNumber)
                                if filtered != newValue { startChapter = filtered }
                                if startChapter.count > 3 { startChapter = String(startChapter.prefix(3)) }

                                // Force correct to max chapters
                                if let chapter = Int(startChapter) {
                                    let max = bibleStore.chapterCount(for: selectedBook)
                                    if chapter > max { startChapter = String(max) }
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
                                    .stroke(
                                        focusedField == .startVerse ? Color.accentColor.opacity(0.8)
                                            : Color.secondary.opacity(0.2),
                                        lineWidth: 1.5,
                                    ),
                            )
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .startVerse)
                            .submitLabel(.next)
                            .onSubmit { focusNext() }
                            .onChange(of: startVerse) { _, newValue in
                                let filtered = newValue.filter(\.isNumber)
                                if filtered != newValue { startVerse = filtered }
                                if startVerse.count > 3 { startVerse = String(startVerse.prefix(3)) }

                                // Force correct to max verses
                                if let chapter = Int(startChapter),
                                   let verse = Int(startVerse)
                                {
                                    let max = bibleStore.verseCount(for: selectedBook, chapter: chapter)
                                    if verse > max { startVerse = String(max) }
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
                                    .stroke(
                                        focusedField == .endChapter ? Color.accentColor.opacity(0.8)
                                            : Color.secondary.opacity(0.2),
                                        lineWidth: 1.5,
                                    ),
                            )
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .endChapter)
                            .submitLabel(.next)
                            .onSubmit { focusNext() }
                            .onChange(of: endChapter) { _, newValue in
                                let filtered = newValue.filter(\.isNumber)
                                if filtered != newValue { endChapter = filtered }
                                if endChapter.count > 3 { endChapter = String(endChapter.prefix(3)) }

                                // Force correct to max chapters
                                if let chapter = Int(endChapter) {
                                    let max = bibleStore.chapterCount(for: selectedBook)
                                    if chapter > max { endChapter = String(max) }
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
                                    .stroke(
                                        focusedField == .endVerse ? Color.accentColor.opacity(0.8)
                                            : Color.secondary.opacity(0.2),
                                        lineWidth: 1.5,
                                    ),
                            )
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .endVerse)
                            .submitLabel(.done)
                            .onSubmit { focusNext() }
                            .onChange(of: endVerse) { _, newValue in
                                let filtered = newValue.filter(\.isNumber)
                                if filtered != newValue { endVerse = filtered }
                                if endVerse.count > 3 { endVerse = String(endVerse.prefix(3)) }

                                // Force correct to max verses
                                if let chapter = Int(endChapter.isEmpty ? startChapter : endChapter),
                                   let verse = Int(endVerse)
                                {
                                    let max = bibleStore.verseCount(for: selectedBook, chapter: chapter)
                                    if verse > max { endVerse = String(max) }
                                }
                            }
                    }

                } footer: {
                    HStack {
                        if bibleStore.state == .loading {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 15, height: 15)
                        }

                        if let chapter = Int(startChapter), bibleStore.isValidChapter(chapter, for: selectedBook) {
                            let verseCount = bibleStore.verseCount(for: selectedBook, chapter: chapter)
                            Text("\(selectedBook) \(chapter) has \(verseCount) verses.")
                        } else {
                            let chapterCount = bibleStore.chapterCount(for: selectedBook)
                            Text("\(selectedBook) has \(chapterCount) chapters.")
                        }
                    }
                    .font(.app(.footnote))
                }

                Section {
                    Text("...")
                } header: {
                    HStack {
                        Text(reference.isEmpty ? "Reference" : reference)
                            .textCase(.uppercase)
                        Spacer()
                        Button {
                            print("refresh")
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.plain)
                    }
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
                    .disabled(!isRefValid)
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
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                if let textField = obj.object as? UITextField {
                    textField.selectAll(nil)
                }
            }
        }
    }
}

// MARK: Helper Views

extension AddPassageView {
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
            .tint(isRefValid ? .green : .primary)
            .disabled(!isRefValid)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: Helper Utils

extension AddPassageView {
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
}

#Preview {
    AddPassageView()
        .environment(\.font, .app())
        .environment(BibleStore.shared)
}
