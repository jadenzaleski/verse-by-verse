//
//  LogsView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 1/15/26.
//

import SwiftUI

struct LogsView: View {
    @State private var logLines: [String] = []
    @State private var logFileURL: URL?
    private let log = AppLog.category("LogsView")

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(Array(logLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(.caption2, design: .monospaced))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
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
            await reload()
        }
        .task {
            await reload()
        }
    }

    private func reload() async {
        let contents = await Task.detached(priority: .userInitiated) {
            LoggingService.shared.readAllLogs()
        }.value
        logLines = contents.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        logFileURL = await Task.detached(priority: .utility) {
            LoggingService.shared.exportLogs(contents: contents)
        }.value
    }
}

#Preview {
    LogsView()
        .environment(\.font, .app())
}
