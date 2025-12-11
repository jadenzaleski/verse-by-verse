//
//  ProfileView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/25/25.
//

import Foundation

import SwiftUI

struct ProfileView: View {
    @State var toggler: Bool = false

    var body: some View {
        ScrollView {
            Image("headshot")
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 150)
                .clipShape(Circle())
                .glassEffect()
                .shadow(color: .black.opacity(0.35), radius: 6, x: 2, y: 2)
                .padding(20)

            Text("@jadenzaleski")
                .padding(.bottom, 1)
                .font(.app(.body, weight: .medium))
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
                                endPoint: .bottomTrailing
                            )
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

            Button {
                toggler.toggle()
            } label: {
                Text("toggle: \(toggler.description)")
            }
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("Jaden Zaleski")
                    .font(.app(.title2, weight: .semibold))
                    .fixedSize()
            }
            .sharedBackgroundVisibility(.hidden)

            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image("lucide.settings")
                }
            }
        }
        .refreshable {
            print("refreshed")
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environment(\.font, .app())
    }
}
