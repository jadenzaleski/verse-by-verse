//
//  SettingsView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/27/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var selectedURL: String = APIConfig.shared.baseURL.absoluteString

    var body: some View {
        List {
            Section {
                Label {
                    Text(AppFunctions.versionString() ?? "")
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
                    Button("Clear Logs", action: {})
                } icon: {
                    Image("lucide.circle")
                }
                Label {
                    Picker("API URL", selection: $selectedURL) {
                        ForEach(APIConfig.shared.urls, id: \.self) { url in
                            Text(url).tag(url)
                        }
                    }
                    .onChange(of: selectedURL) { oldValue, newValue in
                        if let url = URL(string: newValue) {
                            APIConfig.shared.baseURL = url
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
    }
}

#Preview {
    SettingsView()
        .environment(\.font, .app())

}
