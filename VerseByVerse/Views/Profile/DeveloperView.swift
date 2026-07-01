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
    @State private var logFileURL: URL?
    private let log = AppLog.category("DeveloperView")

    private var channelName: String {
        switch AppFunctions.channel {
        case .development: "Development"
        case .beta: "Beta"
        case .production: "Production"
        }
    }

    var body: some View {
        List {
            Section("Build") {
                LabeledContent("Channel", value: channelName)
                LabeledContent("Version", value: AppFunctions.versionString() ?? "—")
            }

            Button("Clear Logs") {
                LoggingService.shared.clearLogs()
                logFileURL = LoggingService.shared.exportLogs()
            }

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
                        .lineLimit(1)
                }
            }
            .onChange(of: selectedURL) { _, newValue in
                if let url = URL(string: newValue) {
                    APIConfig.shared.baseURL = url
                }

                UserStore.shared.logout()
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

            if let logFileURL {
                ShareLink(item: logFileURL) {
                    Label("Share Logs", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle("Developer")
        .onAppear {
            logFileURL = LoggingService.shared.exportLogs()
        }
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
