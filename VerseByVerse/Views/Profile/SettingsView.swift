//
//  SettingsView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/27/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section {
                Label {
                    Text(AppFunctions.versionString() ?? "")
                } icon: {
                    Image("lucide.rocket")
                }
                Label {
                    Text("123-1234-12333435-23423-4234")
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
