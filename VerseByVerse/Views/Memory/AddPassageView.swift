import SwiftUI

struct AddPassageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(BibleStore.self) private var bibleStore
    @State private var passageStore = PassageStore()

    @AppStorage(.lastUsedTranslation) private var selectedTranslation = "KJV"
    @State private var selectedBook = "John"
    @State private var startChapter: String = ""
    @State private var startVerse: String = ""
    @State private var endChapter: String = ""
    @State private var endVerse: String = ""

    @Namespace private var namespace

    @FocusState private var focusedField: Field?

    enum Field: Hashable { case startChapter, startVerse, endChapter, endVerse }

    private var reference: String {
        guard !startChapter.isEmpty, !startVerse.isEmpty else {
            return ""
        }

        let startRef = "\(startChapter):\(startVerse)"

        // If both end fields are empty, it's just the starting point
        if endChapter.isEmpty && endVerse.isEmpty {
            return "\(selectedBook) \(startRef)"
        }

        // Use startChapter as default for endChapter if empty
        let effectiveEndCh = endChapter.isEmpty ? startChapter : endChapter

        if effectiveEndCh == startChapter {
            // Same chapter range like John 3:16–18
            if endVerse.isEmpty {
                return "\(selectedBook) \(startRef)–?"
            } else {
                return "\(selectedBook) \(startRef)–\(endVerse)"
            }
        } else {
            // Cross-chapter range like John 3:16–4:2
            // Always include the colon for the second chapter to avoid ambiguity with verses
            let vsPart = endVerse.isEmpty ? "?" : endVerse
            return "\(selectedBook) \(startRef)–\(effectiveEndCh):\(vsPart)"
        }
    }

    private var isRefValid: Bool {
        guard let startCh = Int(startChapter), let startVs = Int(startVerse) else { return false }

        // Basic range check (already force-corrected in onChange, but good for safety)
        guard bibleStore.isValidChapter(startCh, for: selectedBook),
              bibleStore.isValidVerse(startVs, for: selectedBook, chapter: startCh) else { return false }

        // If something is in the end part
        if !endChapter.isEmpty || !endVerse.isEmpty {
            // Both must be non-empty to be valid
            guard !endChapter.isEmpty, !endVerse.isEmpty else { return false }

            guard let endCh = Int(endChapter), let endVs = Int(endVerse) else { return false }

            // Range checks (end must be logically after start)
            if endCh < startCh { return false }
            if endCh == startCh, endVs < startVs { return false }

            // Validate end range against Bible data
            if !bibleStore.isValidChapter(endCh, for: selectedBook) { return false }
            if !bibleStore.isValidVerse(endVs, for: selectedBook, chapter: endCh) { return false }
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
                    pickers
                    referenceInputGroup
                } footer: {
                    referenceFooter
                }

                Section {
                    if passageStore.state == .loading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                    } else if let passage = passageStore.fetchedPassage {
                        Text(passage.fullText)
                            .font(.app(.body))
                            .transition(.opacity)
                    } else if case let .error(apiError) = passageStore.state {
                        Text(apiError.localizedDescription)
                            .foregroundStyle(.red)
                            .font(.app(.subheadline))
                    } else {
                        Text("Fill out the passage reference above to populate this field.")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    HStack {
                        Text(reference.isEmpty ? "Reference" : reference)
                            .textCase(.uppercase)
                        Spacer()
                        Button {
                            Task {
                                await loadPassage()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .symbolEffect(.bounce, value: passageStore.state == .loading)
                        }
                        .buttonStyle(.plain)
                        .disabled(!isRefValid || passageStore.state == .loading)
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
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await bibleStore.loadBibleData() }
                    group.addTask { await bibleStore.loadTranslations() }
                }
            }
            .onChange(of: bibleStore.availableTranslations) { _, newValue in
                guard let list = newValue, !list.isEmpty else { return }

                // If our current selection isn't in the list, we need a fallback
                let hasSelected = list.contains { item in
                    item.abbreviation == selectedTranslation
                }

                guard !hasSelected else { return }

                // Prefer KJV if present, otherwise first available
                let hasKJV = list.contains { item in
                    item.abbreviation == "KJV"
                }

                if hasKJV {
                    selectedTranslation = "KJV"
                } else if let first = list.first {
                    selectedTranslation = first.abbreviation
                }
            }
            .onChange(of: selectedBook) {
                startChapter = ""
                startVerse = ""
                endChapter = ""
                endVerse = ""
                passageStore.clearPassage()
            }
            .onChange(of: selectedTranslation) {
                passageStore.clearPassage()
            }
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                if let textField = obj.object as? UITextField {
                    textField.selectAll(nil)
                }
            }
        }
    }

    private func loadPassage() async {
        guard isRefValid,
              let startCh = Int(startChapter),
              let startVs = Int(startVerse)
        else { return }

        // Formatting for the API (e.g., "John 3:16")
        let startRef = "\(selectedBook) \(startCh):\(startVs)"
        var endRef: String?

        if !endChapter.isEmpty, !endVerse.isEmpty,
           let endCh = Int(endChapter),
           let endVs = Int(endVerse)
        {
            endRef = "\(selectedBook) \(endCh):\(endVs)"
        }

        await passageStore.fetchPassage(
            translation: selectedTranslation,
            start: startRef,
            end: endRef,
        )
    }
}

// MARK: Helper Views

extension AddPassageView {
    @ViewBuilder
    private var pickers: some View {
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

    private var referenceInputGroup: some View {
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
                focusNext()
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
                focusNext()
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
                focusNext()
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
                focusNext()
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

    private var referenceFooter: some View {
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
                    Task {
                        await loadPassage()
                    }
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

private struct NumericRefTextField: View {
    let placeholder: String
    @Binding var text: String
    let isFocused: Bool
    @FocusState.Binding var focus: AddPassageView.Field?
    let thisField: AddPassageView.Field
    let submitLabel: SubmitLabel
    let width: CGFloat
    let onSubmitAction: () -> Void
    let onChangeAction: (String) -> Void

    init(placeholder: String,
         text: Binding<String>,
         isFocused: Bool,
         focus: FocusState<AddPassageView.Field?>.Binding,
         thisField: AddPassageView.Field,
         submitLabel: SubmitLabel,
         width: CGFloat,
         onSubmit: @escaping () -> Void,
         onChange: @escaping (String) -> Void)
    {
        self.placeholder = placeholder
        _text = text
        self.isFocused = isFocused
        _focus = focus
        self.thisField = thisField
        self.submitLabel = submitLabel
        self.width = width
        onSubmitAction = onSubmit
        onChangeAction = onChange
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.numberPad)
            .textFieldStyle(.plain)
            .frame(width: width)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(.secondarySystemBackground)),
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(isFocused ? Color.accentColor.opacity(0.8) : Color.secondary.opacity(0.2), lineWidth: 1.5),
            )
            .multilineTextAlignment(.center)
            .focused($focus, equals: thisField)
            .submitLabel(submitLabel)
            .onSubmit { onSubmitAction() }
            .onChange(of: text) { _, newValue in
                onChangeAction(newValue)
            }
    }
}

#Preview {
    AddPassageView()
        .environment(\.font, .app())
        .environment(BibleStore.shared)
}
