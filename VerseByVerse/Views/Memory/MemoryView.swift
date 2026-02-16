//
//  MemoryView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/3/25.
//

import SwiftUI

enum MemoryTopTab: String, CaseIterable {
    case all = "All"
    case sets = "Sets"
    case recommended = "Recommended"
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

struct MemoryView: View {
    @State private var selectedTab: MemoryTopTab = .all
    @Namespace private var tabIndicator
    @State private var tabFrames: [MemoryTopTab: CGRect] = [:]
    @State private var scrollOffset: CGFloat = 0

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
            }
            .scrollIndicators(.hidden)
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
        }
        .navigationTitle("Memory")
        .toolbar {
            ToolbarItem {
                NavigationLink {
                    EmptyView()
                } label: {
                    Image("lucide.plus")
                }
                .padding(0)
            }
            //            ToolbarSpacer(.fixed)
            //            ToolbarItem() {
            //                Menu {
            //                    Text("hey")
            //
            //                } label: {
            //                    Image("lucide.ellipsis")
            //                        .imageScale(.medium)
            //                }
            //            }
        }
        .toolbarTitleDisplayMode(.inlineLarge)
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
        case .all:
            VStack(spacing: 10) {
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
                VerseCard()
            }

        case .sets:
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent")
                    .font(.app(.title3))
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 20) {
                        SetCard(title: "The Gospels",
                                passageCount: 24,
                                verseCount: 120,
                                positionSeed: 1,
                                colorShuffleSeed: 123,
                                colorPallette: .ocean)
                            .frame(width: horizontalSetSize)
                    }
                }
                Text("Popular")
                    .font(.app(.title3))
                ScrollView(.horizontal) {
                    LazyHGrid(
                        rows: [GridItem(.adaptive(minimum: horizontalSetSize, maximum: 300), spacing: 20)],
                        spacing: 20,
                    ) {
                        SetCard(title: "The Gospels",
                                passageCount: 24,
                                verseCount: 120,
                                positionSeed: 1,
                                colorShuffleSeed: 67,
                                colorPallette: .ocean)
                            .frame(width: horizontalSetSize)
                        SetCard(title: "Paul's Epistles",
                                passageCount: 13,
                                verseCount: 87,
                                positionSeed: 12,
                                colorShuffleSeed: 1)
                            .frame(width: horizontalSetSize)
                        SetCard(title: "Psalms of Ascent",
                                passageCount: 15,
                                verseCount: 45,
                                positionSeed: 3,
                                colorShuffleSeed: 12)
                            .frame(width: horizontalSetSize)
                        SetCard(title: "Wisdom Literature",
                                passageCount: 5,
                                verseCount: 250,
                                positionSeed: 42,
                                colorShuffleSeed: 12311)
                            .frame(width: horizontalSetSize)
                    }
                }

                Text("All")
                    .font(.app(.title3))
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: gridSetSize, maximum: 250), spacing: 20)
                        ],
                        spacing: 20) {
                        SetCard(title: "The Gospels",
                                passageCount: 24,
                                verseCount: 120,
                                positionSeed: 1,
                                colorShuffleSeed: 123)
                        SetCard(title: "Major Prophets",
                                passageCount: 5,
                                verseCount: 300,
                                positionSeed: 987,
                                colorShuffleSeed: 91)
                        SetCard(title: "Minor Prophets",
                                passageCount: 12,
                                verseCount: 150,
                                positionSeed: 654,
                                colorShuffleSeed: 98)
                        SetCard(title: "Johannine Writings That Are Long",
                                passageCount: 3,
                                verseCount: 60,
                                positionSeed: 316,
                                colorShuffleSeed: 111)
                    }
                }
            }

        case .recommended:
            VStack(spacing: 12) {
                Text("Recommended 1")
                Text("Recommended 2")
            }
        }
    }
}

#Preview {
    MemoryView()
        .environment(\.font, .app())
}
