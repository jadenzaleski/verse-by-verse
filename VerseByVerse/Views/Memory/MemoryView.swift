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

struct TabFrameKey: PreferenceKey {
    static var defaultValue: [MemoryTopTab: CGRect] = [:]
    static func reduce(value: inout [MemoryTopTab: CGRect], nextValue: () -> [MemoryTopTab: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

enum ActiveSheet: Identifiable {
    case add
    case addSet
    case passage(UserPassage)

    var id: String {
        switch self {
        case .add:
            "add"
        case .addSet:
            "addSet"
        case let .passage(id):
            "passage_\(id)"
        }
    }
}

struct MemoryView: View {
    @Environment(PassageStore.self) private var passageStore
    @Environment(StudySetStore.self) private var studySetStore
    @State private var selectedTab: MemoryTopTab = .passages
    @Namespace private var tabIndicator
    @State private var tabFrames: [MemoryTopTab: CGRect] = [:]
    @State private var scrollOffset: CGFloat = 0
    @State private var activeSheet: ActiveSheet?
    private let horizontalSetSize: CGFloat = 135
    private let gridSetSize: CGFloat = 170

    var body: some View {
        VStack(spacing: 0) {
            topTabs

            ScrollView {
                GeometryReader { geo in
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .named("scroll")).minY,
                        )
                }
                .frame(height: 0)
                .id("scroll_tracker_geometry_reader")

                content
                    .transaction { $0.animation = nil }
                    .padding()
                    .task {
                        await passageStore.loadMyPassages(lookInCache: true)
                    }
            }
            .scrollIndicators(.hidden)
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
            .refreshable {
                await passageStore.loadMyPassages()
                await studySetStore.loadMySets()
            }
        }
        .navigationTitle("Memory")
        .toolbar {
            ToolbarItem {
                Button {
                    activeSheet = .addSet
                } label: {
                    Image(systemName: "rectangle.stack.badge.plus")
                }
            }
            ToolbarItem {
                Button {
                    activeSheet = .add
                } label: {
                    Image(systemName: "plus")
                }
                .padding(0)
            }
        }
        .toolbarTitleDisplayMode(.inlineLarge)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .add:
                AddPassageView()
            case .addSet:
                AddStudySetView()
            case let .passage(userPassage):
                NavigationStack {
                    PassageDetailView(passage: userPassage)
                        .navigationTitle("Passage")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .destructiveAction) {
                                Button {
                                    activeSheet = nil
                                } label: {
                                    Image(systemName: "xmark")
                                        .scaleEffect(0.80)
                                }
                            }
                        }
                }
            }
        }
    }

    private var topTabs: some View {
        HStack(spacing: 25) {
            ForEach(MemoryTopTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.snappy) {
                        selectedTab = tab
                    }
                } label: {
                    VStack {
                        Text(tab.rawValue)
                            .font(.app(.body, weight: .semibold))
                            .foregroundStyle(selectedTab == tab ? Color.accentColor : .secondary)
                            .padding(.bottom, 6)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(
                                            key: TabFrameKey.self,
                                            value: [tab: geo.frame(in: .named("tabs"))],
                                        )
                                },
                            )
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.top, max(5, 20 - max(0, -scrollOffset) / 3))
        .coordinateSpace(name: "tabs")
        .onPreferenceChange(TabFrameKey.self) { tabFrames = $0 }
        .background(
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(height: 2)
                    .ignoresSafeArea()
                    .offset(y: 10)

                if let frame = tabFrames[selectedTab] {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: frame.width, height: 2)
                        .offset(x: frame.minX, y: 10)
                        .matchedGeometryEffect(id: "indicator", in: tabIndicator)
                }
            }
            .padding(.top, max(10, 25 - max(0, -scrollOffset) / 3)),
        )
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .passages:
            VStack(spacing: 10) {
                ForEach(passageStore.userPassages, id: \.id) { index in
                    PassageCard(passage: index)
                        .onTapGesture {
                            activeSheet = .passage(index)
                        }
                }

            }

        case .sets:
            VStack(alignment: .leading, spacing: 10) {
                let recentSets = studySetStore.sets
                    .sorted { $0.modifiedAt > $1.modifiedAt }
                    .prefix(5)

                if !recentSets.isEmpty {
                    Text("Recent")
                        .font(.app(.title3))
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 20) {
                            ForEach(Array(recentSets)) { set in
                                SetCard(
                                    title: set.name,
                                    subtitle: set.description,
                                    positionSeed: set.meshPositionSeed,
                                    colorShuffleSeed: set.meshColorSeed,
                                    colorPallette: set.meshTheme.palette,
                                )
                                .frame(width: horizontalSetSize)
                            }
                        }
                    }
                }

                Text("All")
                    .font(.app(.title3))

                if studySetStore.sets.isEmpty {
                    Text("No sets yet — tap \(Image(systemName: "rectangle.stack.badge.plus")) to create one.")
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 16,
                    ) {
                        ForEach(studySetStore.sets) { set in
                            SetCard(
                                title: set.name,
                                subtitle: set.description,
                                positionSeed: set.meshPositionSeed,
                                colorShuffleSeed: set.meshColorSeed,
                                colorPallette: set.meshTheme.palette,
                            )
                        }
                    }
                }
            }
            .task {
                await studySetStore.loadMySets(lookInCache: true)
            }
        }
    }
}

#Preview {
    MemoryView()
        .environment(\.font, .app())
        .environment(UserStore.shared)
        .environment(PassageStore.shared)
        .environment(StudySetStore.shared)
}
