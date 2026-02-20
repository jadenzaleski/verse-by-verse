//
//  HomeView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/25/25.
//

import SwiftUI

struct HomeView: View {
    @State private var user: UserResponse?
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
                Spacer()
            }
            .padding(.horizontal, 10)
        }
        .refreshable {
            log.debug("refreshed")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("\(greeting) \(user?.firstName ?? "")")
                    .font(.app(.title2, weight: .semibold))
                    .fixedSize()
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .task {
            do {
                user = try await APIService.shared.getUser()
            } catch {
                log.error("Failed to load user: \(String(describing: error))")
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(\.font, .app())
    }
}
