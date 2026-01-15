//
//  DeveloperView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 1/15/26.
//

import SwiftUI

struct DeveloperView: View {
    @State private var selectedURL: String = APIConfig.shared.baseURL.absoluteString

    var body: some View {
        List {
            Button("Clear Logs", action: {})

            Button("Clear Cache") {
                Cache.shared.removeAll()
            }

            Picker("API URL", selection: $selectedURL) {
                ForEach(APIConfig.shared.urls, id: \.self) { url in
                    Text(url).tag(url)
                }
            }
            .onChange(of: selectedURL) { _, newValue in
                if let url = URL(string: newValue) {
                    APIConfig.shared.baseURL = url
                }

                Cache.shared.removeAll()
            }

            NavigationLink {
                LogsView()
            } label: {
                Text("Logs")
            }
        }
        .navigationTitle("Developer")
    }
}

#Preview {
    DeveloperView()
        .environment(\.font, .app())
}
