//
//  LogsView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 1/15/26.
//

import SwiftUI

struct LogsView: View {
    @State private var logs: String = ""
    @State private var logFileURL: URL?
    private let log = AppLog.category("LogsView")

    var body: some View {
        ScrollView {
            Text(logs)
                .font(.system(.caption2, design: .monospaced))
        }
        .navigationTitle("Logs")
        .toolbar {
            if let logFileURL {
                ShareLink(item: logFileURL) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .refreshable {
            log.debug("refreshed")
            reload()
        }
        .onAppear(perform: reload)
    }

    private func reload() {
        logs = LoggingService.shared.readAllLogs()
        logFileURL = LoggingService.shared.exportLogs()
    }
}

#Preview {
    LogsView()
        .environment(\.font, .app())
}
