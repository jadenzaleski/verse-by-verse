//
//  DeveloperView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 1/15/26.
//

import SwiftUI

struct DeveloperView: View {
    @State private var showAlert = false
    @State private var alertMessage: String? = ""
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
                LabeledContent("API URL", value: AppFunctions.apiBaseURL.absoluteString)
                    .lineLimit(1)
                LabeledContent("Log Level", value: AppLog.minimumLevel.displayName)
            }

            Button("Clear Logs") {
                LoggingService.shared.clearLogs()
                Task {
                    logFileURL = await Task.detached(priority: .utility) {
                        LoggingService.shared.exportLogs()
                    }.value
                }
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
        .task {
            logFileURL = await Task.detached(priority: .utility) {
                LoggingService.shared.exportLogs()
            }.value
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
