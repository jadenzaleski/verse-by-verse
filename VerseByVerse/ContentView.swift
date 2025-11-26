//
//  ContentView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/22/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", image: "lucide.house")
            }
            .tag(0)

            NavigationStack {
                BibleView()
            }
            .tabItem {
                Label("Bible", image: "lucide.book.open.text")
            }
            .tag(1)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", image: "lucide.user")
            }
            .tag(2)
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView()
}
