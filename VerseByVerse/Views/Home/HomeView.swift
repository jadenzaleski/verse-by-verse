//
//  HomeView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/25/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(UserStore.self) private var userStore
    private let log = AppLog.category("HomeView")
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5 ..< 12:
            return "Good morning"
        case 12 ..< 17:
            return "Good afternoon"
        case 17 ..< 22:
            return "Good evening"
        default:
            return "Good night"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                StreakWidget()
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))

                PracticeHistoryCalendar(sessions: [
                    PracticeSession(id: 1, userId: "u1", passageId: 1,
                                    startDate: Date().addingTimeInterval(-86400 * 2),
                                    endDate: Date().addingTimeInterval(-86400 * 2 + 300),
                                    score: 0.9, rating: 4, scheduledDays: 5, elapsedDays: 2, state: 1),
                    PracticeSession(id: 2, userId: "u1", passageId: 1,
                                    startDate: Date().addingTimeInterval(-86400 * 1),
                                    endDate: Date().addingTimeInterval(-86400 * 1 + 300),
                                    score: 0.8, rating: 3, scheduledDays: 4, elapsedDays: 1, state: 1),
                    PracticeSession(id: 3, userId: "u1", passageId: 1,
                                    startDate: Date(),
                                    endDate: Date().addingTimeInterval(300),
                                    score: 0.95, rating: 5, scheduledDays: 6, elapsedDays: 3, state: 1),
                ])
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))

                Spacer()
            }
            .padding(.horizontal, 10)
        }
        .refreshable {
            log.debug("refreshed")
            await userStore.loadUser(lookInCache: false)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("\(greeting) \(userStore.currentUser?.firstName ?? "")")
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
            .environment(UserStore.shared)
    }
}
