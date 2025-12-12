//
//  HomeView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/25/25.
//

import SwiftUI

struct HomeView: View {
    private let log = AppLog.category("HomeView")

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                StreakWidget()
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                Spacer()
            }
            .padding([.leading, .trailing], 10)
        }
        .refreshable {
            log.debug("refreshed")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("Good evening Jaden")
                    .font(.app(.title2, weight: .semibold))
                    .fixedSize()
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(\.font, .app())
    }
}
