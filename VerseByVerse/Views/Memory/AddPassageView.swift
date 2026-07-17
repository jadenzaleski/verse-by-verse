//
//  AddPassageView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 3/1/26.
//

import SwiftData
import SwiftUI

struct AddPassageView: View {
    /// Called after a successful add with the tab the new item belongs to
    /// (`.verses` for a single verse, `.passages` for a range) so the caller
    /// can surface it — the result type is derived from the selection.
    var onAdded: ((MemoryTopTab) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(BibleStore.self) private var bibleStore
    @Environment(\.modelContext) private var modelContext

    private let log = AppLog.category("AddPassageView")

    @AppStorage(.lastUsedTranslation) private var selectedTranslation = "KJV"
    @State private var selectedBook = "John"
    @State private var startChapter: String = ""
    @State private var startVerse: String = ""
    @State private var endChapter: String = ""
    @State private var endVerse: String = ""

    @Namespace private var namespace

    @FocusState private var focusedField: Field?

    enum Field: Hashable { case startChapter, startVerse, endChapter, endVerse }

    private var currentSelectionKey: BibleSelectionKey? {
        guard let startCh = Int(startChapter), let startVs = Int(startVerse) else { return nil }
        let endCh = Int(endChapter) ?? startCh
        let endVs = Int(endVerse) ?? startVs

        return BibleSelectionKey(
            translation: selectedTranslation,
            book: selectedBook,
            startChapter: startCh,
            startVerse: startVs,
            endChapter: endCh,
            endVerse: endVs,
        )
    }

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
            formView
                .navigationTitle("Add to Memory")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            handleAddPassage()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add to memory")
                        .buttonStyle(.glassProminent)
                        .tint(.accent)
                        .disabled(!isRefValid)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if focusedField != nil {
                        PassageKeyboardBar(
                            namespace: namespace,
                            limits: currentFieldLimits,
                            isRefValid: isRefValid,
                            onPrevious: focusPrevious,
                            onNext: focusNext,
                            onSetValue: setFieldValue,
                        ) {
                            focusedField = nil
                            Task { await loadBibleSelection() }
                        }
                    }
                }
                .task {
                    await loadInitialData()
                }
                .onChange(of: bibleStore.availableTranslations) { _, newValue in
                    handleTranslationsChange(newValue)
                }
                .onChange(of: selectedBook) {
                    handleBookChange()
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: UITextField.textDidBeginEditingNotification,
                )) { obj in
                    handleTextFieldBeginEditing(obj)
                }
        }
    }

    private var formView: some View {
        Form {
            Section {
                PassagePickers(selectedTranslation: $selectedTranslation, selectedBook: $selectedBook)
                ReferenceInputGroup(
                    selectedBook: selectedBook,
                    startChapter: $startChapter,
                    startVerse: $startVerse,
                    endChapter: $endChapter,
                    endVerse: $endVerse,
                    focusedField: $focusedField,
                    onAdvance: focusNext,
                )
            } footer: {
                ReferenceFooterView(startChapter: startChapter, selectedBook: selectedBook)
            }

            Section {
                if bibleStore.state == .loading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                } else if let key = currentSelectionKey, let selection = bibleStore.selections[key] {
                    Text(selection.fullText)
                        .font(.bible(.body))
                        .transition(.opacity)
                } else if case let .error(apiError) = bibleStore.state {
                    Text(apiError.localizedDescription)
                        .foregroundStyle(.red)
                        .font(.app(.subheadline))
                } else {
                    Text("Fill out the passage reference above to populate this field.")
                        .foregroundStyle(.secondary)
                }
            } header: {
                PassageReferenceHeader(reference: reference, isRefValid: isRefValid) {
                    Task { await loadBibleSelection() }
                }
            } footer: {
                Text(" ")
            }
        }
    }

    private func loadInitialData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await bibleStore.loadBibleData() }
            group.addTask { await bibleStore.loadTranslations() }
        }
    }

    private func handleTranslationsChange(_ newValue: [BibleTranslationInfo]?) {
        guard let list = newValue, !list.isEmpty else { return }

        // If our current selection isn't in the list, we need a fallback
        let hasSelected = list.contains { $0.abbreviation == selectedTranslation }
        if hasSelected { return }

        // Prefer KJV if present, otherwise first available
        let hasKJV = list.contains { $0.abbreviation == "KJV" }

        if hasKJV {
            selectedTranslation = "KJV"
        } else if let first = list.first {
            selectedTranslation = first.abbreviation
        }
    }

    private func handleBookChange() {
        startChapter = ""
        startVerse = ""
        endChapter = ""
        endVerse = ""
    }

    private func handleTextFieldBeginEditing(_ notification: Notification) {
        if let textField = notification.object as? UITextField {
            textField.selectAll(nil)
        }
    }

    private func loadBibleSelection() async {
        guard let key = currentSelectionKey, isRefValid else { return }
        await bibleStore.fetchSelection(key)
    }

    /// Adds what the reference describes: a single verse becomes a standalone
    /// `Verse` card; a range becomes a `Passage` whose shared verse cards are
    /// created or reused (memory state carries across containers). Upserts
    /// throughout — re-adding an existing reference is a no-op. Reports the
    /// destination tab via ``onAdded`` so the caller can reveal the result.
    private func handleAddPassage() {
        guard isRefValid else { return }

        let startCh = Int(startChapter) ?? 1
        let startVs = Int(startVerse) ?? 1
        let endCh = Int(endChapter.isEmpty ? startChapter : endChapter) ?? startCh
        let endVs = Int(endVerse.isEmpty ? startVerse : endVerse) ?? startVs

        do {
            if startCh == endCh, startVs == endVs {
                let verse = try Verse.findOrCreate(
                    translation: selectedTranslation,
                    book: selectedBook,
                    chapter: startCh,
                    number: startVs,
                    in: modelContext,
                )
                verse.addedDirectly = true
                try modelContext.save()
                log.info("Added standalone verse \(verse.reference)")
                onAdded?(.verses)
            } else {
                let candidate = Passage(
                    book: selectedBook,
                    startChapter: startCh,
                    endChapter: endCh,
                    startVerse: startVs,
                    endVerse: endVs,
                    translation: selectedTranslation,
                )
                if try Passage.existingDuplicate(of: candidate, in: modelContext) == nil {
                    modelContext.insert(candidate)
                    try candidate.attachVerses(using: bibleStore, in: modelContext)
                    try modelContext.save()
                    log.info("Added passage \(candidate.reference)")
                } else {
                    log.info("Passage already exists, skipping insert")
                }
                onAdded?(.passages)
            }
            dismiss()
        } catch {
            log.error("Failed to add passage: \(error.localizedDescription)")
        }
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
