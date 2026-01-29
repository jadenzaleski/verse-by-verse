//
//  DeveloperView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 1/15/26.
//

import SwiftUI

struct DeveloperView: View {
    @State private var selectedURL: String = APIConfig.shared.baseURL.absoluteString
    @State private var showAlert = false
    @State private var alertMessage: String? = ""
    @State private var selectedLogLevel: LogLevel = AppLog.minimumLevel
    private let log = AppLog.category("DeveloperView")

    var body: some View {
        List {
            Button("Clear Logs", action: {})

            Button("Clear Cache") {
                Cache.shared.removeAll()
            }

            Button {
                Task {
                    do {
                        let result = try await APIService.shared.getHealth()
                        alertMessage = "API Health: \(String(describing: result))"
                        showAlert = true
                    } catch {
                        log.error("API Health check failed: \(String(describing: error))")
                        alertMessage = "API Health check failed: \(String(describing: error))"
                        showAlert = true
                    }
                }
            } label: {
                Text("API Healthcheck")
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

            Picker("Log Level", selection: $selectedLogLevel) {
                ForEach(LogLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .onChange(of: selectedLogLevel) { _, newValue in
                AppLog.setMinimumLevel(newValue)
            }

            NavigationLink {
                LogsView()
            } label: {
                Text("Logs")
            }
        }
        .navigationTitle("Developer")
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text("Health Check"),
                  message: Text(alertMessage ?? "No message"),
                  dismissButton: .default(Text("OK")))
        })
    }
}

#Preview {
    DeveloperView()
        .environment(\.font, .app())
}
