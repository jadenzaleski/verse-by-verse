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
    case sets = "Sets"
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
    @Query(sort: \Passage.createdAt, order: .reverse) private var passages: [Passage]
    @Query(sort: \StudySet.modifiedAt, order: .reverse) private var studySets: [StudySet]

    @State private var searchText: String = ""
    @State private var selectedTab: MemoryTopTab = .passages
    @State private var activeSheet: ActiveSheet?
    @State private var scrollPosition: ScrollPosition = .init(y: 1)
    private let horizontalSetSize: CGFloat = 135

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
                    .transaction { $0.animation = nil }
            }
            .padding(.horizontal)
        }
        .scrollPosition($scrollPosition)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search passages and sets",
        )
        .navigationTitle("Memory")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        activeSheet = .add
                    } label: {
                        Label("New Passage", systemImage: "plus")
                    }
                    Button {
                        activeSheet = .addSet
                    } label: {
                        Label("New Set", systemImage: "rectangle.stack.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add passage or set")
            }
        }
        .toolbarTitleDisplayMode(.large)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .add:
                AddPassageView()
            case .addSet:
                StudySetFormView(
                    title: "New Set",
                    confirmSystemImage: "plus",
                    confirmTint: .green,
                ) { name, description, theme in
                    let set = StudySet(name: name, setDescription: description, meshTheme: theme)
                    modelContext.insert(set)
                    try modelContext.save()
                    log.info("Created study set \(name)")
                }
            }
        }
    }

    private var hasQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var filteredPassages: [Passage] {
        guard hasQuery else { return passages }
        return passages.filter {
            $0.reference.localizedCaseInsensitiveContains(searchText)
                || $0.translation.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredSets: [StudySet] {
        guard hasQuery else { return studySets }
        return studySets.filter {
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
                            : "No passages yet — tap \(Image(systemName: "plus")) to create one.",
                    )
                }
                ForEach(filteredPassages) { passage in
                    NavigationLink(destination: PassageDetailView(passage: passage)) {
                        PassageCard(passage: passage)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            delete(passage)
                        } label: {
                            Label("Delete Passage", systemImage: "trash")
                        }
                    }
                }
            }

        case .sets:
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if !hasQuery {
                    let recentSets = filteredSets.prefix(5)

                    if !recentSets.isEmpty {
                        Text("Recent")
                            .font(.app(.title3))
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: AppSpacing.xl) {
                                ForEach(Array(recentSets)) { set in
                                    NavigationLink(destination: SetDetailView(set: set)) {
                                        SetCard(
                                            title: set.name,
                                            passageCount: set.passages?.count,
                                            verseCount: setVerseCount(set),
                                            description: set.setDescription,
                                            positionSeed: set.meshPositionSeed,
                                            colorShuffleSeed: set.meshColorSeed,
                                            colorPallette: set.meshTheme.palette,
                                        )
                                    }
                                    .frame(width: horizontalSetSize)
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
                            : "No sets yet — tap \(Image(systemName: "plus")) to create one.",
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
                                    passageCount: set.passages?.count,
                                    verseCount: setVerseCount(set),
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

    /// Total verse count across a set's passages.
    private func setVerseCount(_ set: StudySet) -> Int? {
        set.passages.map { passages in
            passages.reduce(0) { $0 + $1.verseCount(using: bibleStore) }
        }
    }

    private func delete(_ passage: Passage) {
        modelContext.delete(passage)
        do {
            try modelContext.save()
        } catch {
            log.error("Failed to delete passage: \(error)")
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
