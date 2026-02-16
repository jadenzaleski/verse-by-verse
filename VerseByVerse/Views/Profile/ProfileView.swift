//
//  ProfileView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/25/25.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    private let log = AppLog.category("ProfileView")
    @State private var user: UserResponse?

    var body: some View {
        let firstName = user?.firstName ?? "Uknown"
        let lastName = user?.lastName ?? ""
        ScrollView {
            Image("headshot")
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 150)
                .clipShape(Circle())
                .glassEffect()
                .shadow(color: .black.opacity(0.35), radius: 6, x: 2, y: 2)
                .padding(20)

            Text("Since November 14th, 2025")
                .font(.app(.footnote))
                .foregroundStyle(.secondary)

            HStack(spacing: 60) {
                VStack {
                    Text("123")
                        .font(.app(.body, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("CustomPurple"), Color("CustomGreen")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing,
                            ),
                        )
                    Text("Best Streak")
                        .font(.app(.footnote))
                }

                VStack {
                    Text("456")
                        .font(.app(.body, weight: .bold))
                    Text("Verses")
                        .font(.app(.footnote))
                }
            }
            .padding(10)
            Text(user?.lastLogin?.formatted(date: .long, time: .complete) ?? "Never logged in")
            Spacer()
        }
        .navigationTitle("\(firstName) \(lastName)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image("lucide.settings")
                }
            }
        }
        .toolbarTitleDisplayMode(.inlineLarge)
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
        ProfileView()
            .environment(\.font, .app())
    }
}
