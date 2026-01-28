//
//  SettingsView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/27/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("id") private var id: String?
    var body: some View {
        List {
            Section {} header: {
                Text("PROFILE")
                    .font(Font.app(.footnote, weight: .semibold))
            }

            Section {} header: {
                Text("APPEARANCE")
                    .font(Font.app(.footnote, weight: .semibold))
            }

            Section {
                Label {
                    Text(AppFunctions.versionString() ?? "")
                } icon: {
                    Image("lucide.rocket")
                }
                Label {
                    Text(id ?? "Unknown id")
                } icon: {
                    Image("lucide.id.card.lanyard")
                }

            } header: {
                Text("ABOUT")
                    .font(Font.app(.footnote, weight: .semibold))
            }

            Section {
                NavigationLink {
                    DeveloperView()
                } label: {
                    Label("Developer", image: "lucide.hammer")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environment(\.font, .app())
}
