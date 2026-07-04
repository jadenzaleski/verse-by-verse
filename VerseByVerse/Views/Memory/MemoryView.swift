//
//  MemoryView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/3/25.
//

import SwiftUI

enum MemoryTopTab: String, CaseIterable {
    case passages = "Passages"
    case sets = "Sets"
}

enum ActiveSheet: Identifiable {
    case add
    case addSet

    var id: String {
        switch self {
        case .add:
            "add"
        case .addSet:
            "addSet"
        }
    }
}

struct MemoryView: View {
    @Environment(PassageStore.self) private var passageStore
    @Environment(StudySetStore.self) private var studySetStore
    @Environment(BibleStore.self) private var bibleStore
    @State private var searchText: String = ""
    @State private var selectedTab: MemoryTopTab = .passages
    @State private var activeSheet: ActiveSheet?
    @State private var scrollPosition: ScrollPosition = .init(y: 1)
    private let horizontalSetSize: CGFloat = 135
    private let gridSetSize: CGFloat = 170

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
            .task {
                await passageStore.loadMyPassages(lookInCache: true)
            }
        }
        .scrollPosition($scrollPosition)
        .refreshable {
            await passageStore.loadMyPassages()
            await studySetStore.loadMySets()
        }
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
                    try await studySetStore.createSet(name: name, description: description, theme: theme)
                }
            }
        }
    }

    private var hasQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var filteredPassages: [UserPassage] {
        guard hasQuery else { return passageStore.userPassages }
        return passageStore.userPassages.filter {
            $0.reference.localizedCaseInsensitiveContains(searchText)
                || $0.translation.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredSets: [StudySet] {
        guard hasQuery else { return studySetStore.sets }
        return studySetStore.sets.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
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
                ForEach(filteredPassages, id: \.id) { passage in
                    NavigationLink(destination: PassageDetailView(passage: passage)) {
                        PassageCard(passage: passage)
                    }
                    .buttonStyle(.plain)
                }
            }

        case .sets:
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if !hasQuery {
                    let recentSets = filteredSets
                        .sorted { $0.modifiedAt > $1.modifiedAt }
                        .prefix(5)

                    if !recentSets.isEmpty {
                        Text("Recent")
                            .font(.app(.title3))
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: AppSpacing.xl) {
                                ForEach(Array(recentSets)) { set in
                                    NavigationLink(destination: SetDetailView(set: set)) {
                                        SetCard(
                                            title: set.name,
                                            passageCount: setPassageCount(set),
                                            verseCount: setVerseCount(set),
                                            description: set.description,
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

                    let space: CGFloat = 20.0
                    let columns = [
                        GridItem(.flexible(), spacing: space),
                        GridItem(.flexible(), spacing: space),
                    ]
                    LazyVGrid(
                        columns: columns,
                        spacing: space,
                    ) {
                        ForEach(filteredSets) { set in
                            NavigationLink(destination: SetDetailView(set: set)) {
                                SetCard(
                                    title: set.name,
                                    passageCount: setPassageCount(set),
                                    verseCount: setVerseCount(set),
                                    description: set.description,
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
            .task {
                await studySetStore.loadMySets(lookInCache: true)
            }
        }
    }

    /// Number of passages in a set, or nil if membership hasn't loaded yet.
    private func setPassageCount(_ set: StudySet) -> Int? {
        studySetStore.setPassageIds[set.id]?.count
    }

    /// Total verse count across a set's passages, resolved live from `PassageStore`.
    private func setVerseCount(_ set: StudySet) -> Int? {
        studySetStore.setPassageIds[set.id].map { ids in
            ids.compactMap { passageStore.passagesById[$0] }
                .reduce(0) { $0 + $1.verseCount(using: bibleStore) }
        }
    }

    private func emptyMessage(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.app(.subheadline))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 40)
    }
}

#Preview {
    let passageStore = PassageStore.shared
    let studySetStore = StudySetStore.shared

    let samplePassages: [UserPassage] = (1 ... 12).map { idx in
        UserPassage(
            id: idx,
            userId: "preview",
            book: ["John", "Romans", "Psalms", "Genesis"][idx % 4],
            startChapter: idx,
            endChapter: idx,
            startVerse: 1,
            endVerse: 5 + idx,
            translation: ["KJV", "NIV", "ESV"][idx % 3],
            lastPracticed: nil,
            nextPractice: nil,
            stability: 1.0,
            difficulty: 1.0,
            state: 1,
            reps: idx,
            lapses: 0,
            scheduledDays: 1,
            elapsedDays: 0,
        )
    }

    let sampleSets: [StudySet] = [
        StudySet(
            id: 1,
            userId: "preview",
            name: "Sermon on the Mount",
            description: "Matthew 5-7, the core teachings of Jesus.",
            meshPositionSeed: 1024,
            meshColorSeed: 4096,
            meshTheme: .ocean,
            createdAt: .now.addingTimeInterval(-86400 * 14),
            modifiedAt: .now.addingTimeInterval(-3600),
        ),
        StudySet(
            id: 2,
            userId: "preview",
            name: "Psalms of Praise",
            description: nil,
            meshPositionSeed: 2048,
            meshColorSeed: 8192,
            meshTheme: .sunset,
            createdAt: .now.addingTimeInterval(-86400 * 30),
            modifiedAt: .now.addingTimeInterval(-86400 * 2),
        ),
        StudySet(
            id: 3,
            userId: "preview",
            name: "Fruit of the Spirit",
            description: "Galatians 5:22-23 — love, joy, peace, and more.",
            meshPositionSeed: 3072,
            meshColorSeed: 1234,
            meshTheme: .forest,
            createdAt: .now.addingTimeInterval(-86400 * 7),
            modifiedAt: .now.addingTimeInterval(-86400),
        ),
        StudySet(
            id: 4,
            userId: "preview",
            name: "Quick Verses",
            description: nil,
            meshPositionSeed: 4096,
            meshColorSeed: 5678,
            meshTheme: .ocean,
            createdAt: .now.addingTimeInterval(-86400 * 3),
            modifiedAt: .now.addingTimeInterval(-86400 * 3),
        ),
        StudySet(
            id: 5,
            userId: "preview",
            name: "Romans Road",
            description: "Key verses outlining the gospel from Romans.",
            meshPositionSeed: 5120,
            meshColorSeed: 9012,
            meshTheme: .sunset,
            createdAt: .now.addingTimeInterval(-86400 * 60),
            modifiedAt: .now.addingTimeInterval(-86400 * 5),
        ),
        StudySet(
            id: 6,
            userId: "preview",
            name: "Daily Devotional",
            description: nil,
            meshPositionSeed: 6144,
            meshColorSeed: 3456,
            meshTheme: .forest,
            createdAt: .now.addingTimeInterval(-86400 * 21),
            modifiedAt: .now.addingTimeInterval(-86400 * 10),
        ),
    ]

    NavigationStack {
        MemoryView()
            .environment(\.font, .app())
            .environment(UserStore.shared)
            .environment(passageStore)
            .environment(studySetStore)
            .environment(BibleStore.shared)
    }
    #if DEBUG
    .task {
            passageStore.setUserPassagesForPreview(samplePassages)
            studySetStore.setSetsForPreview(sampleSets)
            studySetStore.setPassageIdsForPreview([
                1: samplePassages.prefix(4).map(\.id),
                2: samplePassages.prefix(2).map(\.id),
                3: samplePassages.map(\.id),
            ])
        }
    #endif
}
