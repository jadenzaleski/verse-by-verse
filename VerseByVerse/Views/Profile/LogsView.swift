//
//  LogsView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 1/15/26.
//

import SwiftUI

struct LogsView: View {
    @State private var logs: String = ""
    private let log = AppLog.category("LogsView")

    var body: some View {
        ScrollView {
            Text(logs)
                .font(.system(.caption2, design: .monospaced))
        }
        .navigationTitle("Logs")
        .refreshable {
            log.debug("refreshed")
            logs = LoggingService.shared.readAllLogs()
        }
        .onAppear {
            logs = LoggingService.shared.readAllLogs()
        }
    }
}

#Preview {
    LogsView()
        .environment(\.font, .app())
}
