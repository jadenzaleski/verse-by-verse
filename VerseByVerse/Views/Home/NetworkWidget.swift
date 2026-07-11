//
//  NetworkWidget.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/11/26.
//

import SwiftUI

/// Shown on Home whenever the app isn't fully online — distinguishes "your
/// device has no connection" from "we can't reach our server" since they
/// call for different messaging (and the second one still means your Wi-Fi
/// is fine).
struct NetworkWidget: View {
    enum Issue {
        case deviceOffline
        case serverUnreachable

        var icon: String {
            switch self {
            case .deviceOffline: "icloud.slash"
            case .serverUnreachable: "exclamationmark.triangle"
            }
        }

        var tint: Color {
            switch self {
            case .deviceOffline: .orange
            case .serverUnreachable: .appDestructive
            }
        }

        var title: String {
            switch self {
            case .deviceOffline: "You're Offline"
            case .serverUnreachable: "Can't Reach Server"
            }
        }

        var subtitle: String {
            switch self {
            case .deviceOffline, .serverUnreachable:
                "Previously loaded verses are still available."
            }
        }
    }

    let issue: Issue

    var body: some View {
        HStack {
            Image(systemName: issue.icon)
                .font(.app(.title3))
                .foregroundStyle(issue.tint)

            VStack(alignment: .leading) {
                Text(issue.title)
                    .font(.app(.headline))
                    .foregroundStyle(issue.tint)

                Text(issue.subtitle)
                    .font(.app(.caption))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }
}

#Preview("Device Offline") {
    NetworkWidget(issue: .deviceOffline)
        .environment(\.font, .app())
}

#Preview("Server Unreachable") {
    NetworkWidget(issue: .serverUnreachable)
        .environment(\.font, .app())
}
