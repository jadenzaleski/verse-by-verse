//
//  HomeView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/25/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                HStack {
                    Text("Good evening Jaden!")
                        .font(.app(.title2, weight: .semibold))
                    Spacer()
                }
                StreakWidget()
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                Spacer()
            }
            .padding([.leading, .trailing], 10)
        }
        .refreshable {
            print("refreshed")
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(\.font, .app())
    }
}
