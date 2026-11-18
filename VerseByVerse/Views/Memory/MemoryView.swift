//
//  MemoryView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/3/25.
//

import SwiftData
import SwiftUI

enum MemoryTopTab: String, CaseIterable {
    case passages = "Passages"
    case verses = "Verses"
    case sets = "Sets"
}

/// How passages and verses are ordered. Each case has a natural direction
/// (see `MemoryView.sortKey`); "Reverse Order" flips it.
enum MemorySort: String, CaseIterable, Identifiable {
    case dueSoonest
    case reference
    case memoryScore
    case dateAdded
    case lastPracticed

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
        case .dueSoonest: "Up Next"
        case .reference: "Canonical Order"
        case .memoryScore: "Memory Score"
        case .dateAdded: "Date Added"
        case .lastPracticed: "Date Practiced"
        }
    }

    var icon: Image {
        switch self {
        case .dueSoonest: Image("lucide.clock.exclamation.point")
        case .reference: Image("lucide.library")
        case .memoryScore: Image("lucide.brain")
        case .dateAdded: Image("lucide.calendar.plus")
        case .lastPracticed: Image("lucide.calendar.clock")
        }
    }
}

/// How study sets are ordered.
enum SetSort: String, CaseIterable, Identifiable {
    case dateModified
    case dateAdded
    case name

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
        case .dateModified: "Date Modified"
        case .dateAdded: "Date Added"
        case .name: "Name"
        }
    }

    var icon: Image {
        switch self {
        case .dateModified: Image("lucide.calendar.clock")
        case .dateAdded: Image("lucide.calendar.plus")
        case .name: Image("lucide.arrow.down.a.z")
        }
    }
}

/// Restricts passages and verses to one testament.
enum TestamentFilter: String, CaseIterable, Identifiable {
    case all
    case old
    case new

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
        case .all: "All Books"
        case .old: "Old Testament"
        case .new: "New Testament"
        }
    }

    /// Books in the Old Testament (Genesis through Malachi).
    static let oldTestamentBookCount = 39
}

/// Sort key with a deterministic tiebreaker (`sorted` isn't stable).
private struct SortKey: Comparable {
    let primary: Double
    let tiebreak: String

    static func < (lhs: SortKey, rhs: SortKey) -> Bool {
        (lhs.primary, lhs.tiebreak) < (rhs.primary, rhs.tiebreak)
    }
}

struct MemoryView: View {
    private enum ActiveSheet: Identifiable {
        case add
        case addSet

        var id: String {
            switch self {
            case .add: "add"
            case .addSet: "addSet"
            }
        }
    }

    @Environment(BibleStore.self) private var bibleStore
    @Environment(\.modelContext) private var modelContext
    @Query private var passages: [Passage]
    @Query private var verses: [Verse]
    @Query(sort: \StudySet.modifiedAt, order: .reverse) private var studySets: [StudySet]

    @AppStorage(.memorySort) private var memorySort: MemorySort = .dueSoonest
    @AppStorage(.setSort) private var setSort: SetSort = .dateModified
    @AppStorage(.sortReversed) private var sortReversed = false
    @AppStorage(.filterDueOnly) private var dueOnly = false
    @AppStorage(.filterTestament) private var testament: TestamentFilter = .all

    @State private var searchText: String = ""
    @State private var selectedTab: MemoryTopTab = .passages
    @State private var activeSheet: ActiveSheet?
    @State private var scrollPosition: ScrollPosition = .init(y: 1)
    private let rowAnimation = Animation.snappy

    private let scheduler = FSRSScheduler()
    private let log = AppLog.category("MemoryView")

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.sm) {
                Picker("View", selection: $selectedTab) {
                    ForEach(MemoryTopTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom, AppSpacing.md)

                content
                    .transaction(value: selectedTab) { $0.animation = nil }
            }
            .padding(.horizontal)
        }
        .swipeActionsContainer()
        .scrollPosition($scrollPosition)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search passages, verses, and sets",
        )
        .navigationTitle("Memory")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                sortMenu
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        activeSheet = .add
                    } label: {
                        Label("Add Verse/Passage", image: "lucide.plus")
                    }
                    Button {
                        activeSheet = .addSet
                    } label: {
                        Label("Add Set", image: "lucide.layers.plus")
                    }
                } label: {
                    Image("lucide.plus")
                }
                .accessibilityLabel("Add passage or set")
            }
        }
        .toolbarTitleDisplayMode(.large)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .add:
                AddToMemoryView { destination in
                    selectedTab = destination
                }
            case .addSet:
                AddSetView(
                    title: "New Set",
                    confirmImage: "lucide.plus",
                    confirmTint: .green,
                ) { name, description, theme, positionSeed, colorSeed in
                    let set = StudySet(
                        name: name,
                        setDescription: description,
                        meshPositionSeed: positionSeed,
                        meshColorSeed: colorSeed,
                        meshTheme: theme,
                    )
                    modelContext.insert(set)
                    try modelContext.save()
                    log.info("Created study set \(name)")
                    selectedTab = .sets
                }
            }
        }
    }

    private var hasQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var sortMenu: some View {
        Menu {
            Group {
                if selectedTab == .sets {
                    Picker("Sort By", selection: $setSort) {
                        ForEach(SetSort.allCases) { sort in
                            Label { Text(sort.title) } icon: { sort.icon }.tag(sort)
                        }
                    }
                    .pickerStyle(.inline)
                } else {
                    Picker("Sort By", selection: $memorySort) {
                        ForEach(MemorySort.allCases) { sort in
                            Label { Text(sort.title) } icon: { sort.icon }.tag(sort)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section {
                    Toggle(isOn: $sortReversed) {
                        Label("Reverse Order", image: "lucide.arrow.up.down")
                    }
                }

                if selectedTab != .sets {
                    Menu {
                        Group {
                            Toggle(isOn: $dueOnly) {
                                Label("Due Now", image: "lucide.bell.dot")
                            }
                            Picker("Testament", selection: $testament) {
                                ForEach(TestamentFilter.allCases) { filter in
                                    Text(filter.title).tag(filter)
                                }
                            }
                        }
                        .tint(Color.primary)
                    } label: {
                        Label("Filter", image: "lucide.funnel")
                    }
                    // The funnel shows the active tint; its own rows stay neutral.
                    .tint(hasActiveFilter ? Color.appAccent : Color.primary)
                }
            }
            // Keep the rows neutral; only the toolbar button shows the active tint.
            .tint(Color.primary)
        } label: {
            Label("Sort and Filter", image: "lucide.list.filter")
        }
        .tint(hasActiveFilter ? Color.appAccent : nil)
        .accessibilityLabel("Sort and filter")
    }

    /// Canonical position of each book, for Bible-order sorting.
    private var bookIndex: [String: Int] {
        Dictionary(
            uniqueKeysWithValues: bibleStore.bibleBooksOrder.enumerated().map { ($1, $0) },
        )
    }

    /// Whether `book` passes the testament filter.
    private func matchesTestament(_ book: String) -> Bool {
        guard testament != .all else { return true }
        let isOld = bookIndex[book].map { $0 < TestamentFilter.oldTestamentBookCount } ?? false
        return isOld == (testament == .old)
    }

    private var hasActiveFilter: Bool {
        dueOnly || testament != .all
    }

    /// Orders `items` by `key` (ascending), flipped when "Reverse Order" is on.
    /// Keys are computed once per item rather than inside the comparator.
    private func ordered<T>(_ items: [T], key: (T) -> SortKey) -> [T] {
        items
            .map { ($0, key($0)) }
            .sorted { sortReversed ? $0.1 > $1.1 : $0.1 < $1.1 }
            .map(\.0)
    }

    private func referenceKey(book: String, chapter: Int, verse: Int, books: [String: Int]) -> Double {
        Double((books[book] ?? 999) * 1_000_000 + chapter * 1000 + verse)
    }

    private var sortedPassages: [Passage] {
        let books = bookIndex
        let now = Date.now
        return ordered(passages) { passage in
            let primary: Double = switch memorySort {
            case .dueSoonest:
                // Unpracticed verses count as due, so the passage is due now.
                if (passage.verses ?? []).contains(where: \.isNew) {
                    -.infinity
                } else {
                    passage.nextPractice?.timeIntervalSinceReferenceDate ?? .infinity
                }
            case .reference:
                referenceKey(book: passage.book, chapter: passage.startChapter, verse: passage.startVerse, books: books)
            case .memoryScore:
                passage.memoryScore(using: scheduler, at: now) ?? 0
            case .dateAdded:
                -passage.createdAt.timeIntervalSinceReferenceDate
            case .lastPracticed:
                -(passage.lastPracticed?.timeIntervalSinceReferenceDate ?? -.infinity)
            }
            return SortKey(primary: primary, tiebreak: passage.reference + passage.translation)
        }
    }

    private var filteredPassages: [Passage] {
        var result = sortedPassages
        if dueOnly {
            result = result.filter { $0.isDue() }
        }
        if testament != .all {
            result = result.filter { matchesTestament($0.book) }
        }
        guard hasQuery else { return result }
        return result.filter {
            $0.reference.localizedCaseInsensitiveContains(searchText)
                || $0.translation.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var sortedVerses: [Verse] {
        let books = bookIndex
        let now = Date.now
        return ordered(verses) { verse in
            let primary: Double = switch memorySort {
            case .dueSoonest:
                verse.isNew ? -.infinity : (verse.nextPractice?.timeIntervalSinceReferenceDate ?? .infinity)
            case .reference:
                referenceKey(book: verse.book, chapter: verse.chapter, verse: verse.number, books: books)
            case .memoryScore:
                scheduler.retrievability(of: verse.memoryState, at: now)
            case .dateAdded:
                -verse.createdAt.timeIntervalSinceReferenceDate
            case .lastPracticed:
                -(verse.lastPracticed?.timeIntervalSinceReferenceDate ?? -.infinity)
            }
            return SortKey(primary: primary, tiebreak: verse.reference + verse.translation)
        }
    }

    private var filteredVerses: [Verse] {
        var result = sortedVerses
        if dueOnly {
            result = result.filter { $0.isDue() }
        }
        if testament != .all {
            result = result.filter { matchesTestament($0.book) }
        }
        guard hasQuery else { return result }
        return result.filter {
            $0.reference.localizedCaseInsensitiveContains(searchText)
                || $0.translation.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var sortedSets: [StudySet] {
        ordered(studySets) { set in
            switch setSort {
            case .dateModified:
                SortKey(primary: -set.modifiedAt.timeIntervalSinceReferenceDate, tiebreak: set.name)
            case .dateAdded:
                SortKey(primary: -set.createdAt.timeIntervalSinceReferenceDate, tiebreak: set.name)
            case .name:
                SortKey(primary: 0, tiebreak: set.name.localizedLowercase)
            }
        }
    }

    private var filteredSets: [StudySet] {
        guard hasQuery else { return sortedSets }
        return sortedSets.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || ($0.setDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .passages:
            VStack(spacing: AppSpacing.md) {
                if filteredPassages.isEmpty {
                    emptyMessage(
                        hasQuery
                            ? "No passages match your search."
                            : hasActiveFilter ? "Nothing matches your filters."
                            : "No passages yet — tap \(Image("lucide.plus")) to create one.",
                    )
                }
                ForEach(filteredPassages) { passage in
                    PassageSwipeRow(passage: passage) { alsoDeleteVerses in
                        delete(passage, alsoDeleteVerses: alsoDeleteVerses)
                    }
                }
            }
            .animation(rowAnimation, value: filteredPassages.map(\.persistentModelID))

        case .verses:
            VStack(spacing: AppSpacing.md) {
                if filteredVerses.isEmpty {
                    emptyMessage(
                        hasQuery
                            ? "No verses match your search."
                            : hasActiveFilter ? "Nothing matches your filters."
                            : "No verses yet.",
                    )
                }
                ForEach(filteredVerses) { verse in
                    VerseSwipeRow(verse: verse) {
                        delete(verse)
                    }
                }
            }
            .animation(rowAnimation, value: filteredVerses.map(\.persistentModelID))

        case .sets:
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if !hasQuery {
                    let recentSets = studySets.prefix(5)

                    if !recentSets.isEmpty {
                        Text("Recent")
                            .font(.app(.title3))
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: AppSpacing.xl) {
                                ForEach(Array(recentSets)) { set in
                                    NavigationLink(destination: SetDetailView(set: set)) {
                                        SetCard(
                                            title: set.name,
                                            passageCount: set.totalPassageCount,
                                            verseCount: set.totalVerseCount,
                                            description: set.setDescription,
                                            positionSeed: set.meshPositionSeed,
                                            colorShuffleSeed: set.meshColorSeed,
                                            colorPallette: set.meshTheme.palette,
                                        )
                                    }
                                    .containerRelativeFrame(.horizontal, count: 3, spacing: AppSpacing.xl)
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                if filteredSets.isEmpty {
                    emptyMessage(
                        hasQuery
                            ? "No sets match your search."
                            : "No sets yet — tap \(Image("lucide.plus")) to create one.",
                    )
                } else {
                    Text("All")
                        .font(.app(.title3))

                    let columns = [
                        GridItem(.flexible(), spacing: AppSpacing.xl),
                        GridItem(.flexible(), spacing: AppSpacing.xl),
                    ]
                    LazyVGrid(
                        columns: columns,
                        spacing: AppSpacing.xl,
                    ) {
                        ForEach(filteredSets) { set in
                            NavigationLink(destination: SetDetailView(set: set)) {
                                SetCard(
                                    title: set.name,
                                    passageCount: set.totalPassageCount,
                                    verseCount: set.totalVerseCount,
                                    description: set.setDescription,
                                    positionSeed: set.meshPositionSeed,
                                    colorShuffleSeed: set.meshColorSeed,
                                    colorPallette: set.meshTheme.palette,
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func delete(_ passage: Passage, alsoDeleteVerses: Bool) {
        do {
            try passage.delete(alsoDeleteVerses: alsoDeleteVerses, in: modelContext)
        } catch {
            log.error("Failed to delete passage: \(error)")
        }
    }

    private func delete(_ verse: Verse) {
        do {
            try verse.deleteFromLibrary(in: modelContext)
        } catch {
            log.error("Failed to delete verse: \(error)")
        }
    }

    private func emptyMessage(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.app(.subheadline))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, AppSpacing.xxl)
    }
}

#Preview {
    NavigationStack {
        MemoryView()
            .modelContainer(PreviewData.container)
            .environment(\.font, .app())
            .environment(BibleStore.shared)
    }
}
