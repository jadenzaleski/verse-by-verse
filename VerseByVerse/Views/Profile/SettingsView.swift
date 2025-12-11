//
//  SettingsView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/27/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

    @State private var selectedURL: String = "Chocolate"

    let URLs = ["Chocolate", "Vanilla", "Strawberry"]

    var body: some View {
        List {
            Section {
                Label {
                    Text("v\(version) (\(build))")
                } icon: {
                    Image("lucide.circle")
                }
                Label {
                    Text("123-1234-12333435-23423-4234")
                } icon: {
                    Image("lucide.circle")
                }

            } header: {
                Text("ABOUT")
                    .font(Font.app(.footnote, weight: .semibold))
            }

            Section {
                Label {
                    Button("Clear Cache", action: {})
                } icon: {
                    Image("lucide.circle")
                }
                Label {
                    Picker("API URL", selection: $selectedURL) {
                        ForEach(URLs, id: \.self) { url in
                            Text(url).tag(url)
                        }
                    }
                } icon: {
                    Image("lucide.circle")
                }
            } header: {
                Text("ADMIN")
                    .font(Font.app(.footnote, weight: .semibold))
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image("lucide.chevron.left")
                        .font(.app(.footnote))
                }

            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.font, .app())

}
