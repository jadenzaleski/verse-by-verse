//
//  LoadFailureView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/8/26.
//

import SwiftUI

/// Full-screen "couldn't load" state with a retry, shared by every screen that
/// blocks on a network fetch. Offline errors get the screen's own friendly
/// `offlineMessage`; anything else shows the `APIError`'s description.
struct LoadFailureView: View {
    let title: LocalizedStringKey
    let error: APIError?
    let offlineMessage: LocalizedStringKey
    let onRetry: () -> Void
    var onClose: (() -> Void)?

    private var isOffline: Bool {
        guard case .network? = error else { return false }
        return true
    }

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: isOffline ? "wifi.slash" : "exclamationmark.triangle")
        } description: {
            if isOffline {
                Text(offlineMessage)
            } else {
                Text(error?.localizedDescription ?? "Something went wrong.")
            }
        } actions: {
            Button("Try Again", action: onRetry)
            if let onClose {
                Button("Close", action: onClose)
            }
        }
    }
}

extension View {
    /// Runs `action` when the network monitor reports a successful request
    /// while `isFailed` — so a screen stuck on a failed load recovers on its
    /// own once connectivity returns, without the user tapping Try Again.
    func retryWhenOnline(if isFailed: Bool, perform action: @escaping () async -> Void) -> some View {
        modifier(RetryWhenOnline(isFailed: isFailed, action: action))
    }
}

private struct RetryWhenOnline: ViewModifier {
    let isFailed: Bool
    let action: () async -> Void
    private let networkMonitor = NetworkMonitor.shared

    func body(content: Content) -> some View {
        content.onChange(of: networkMonitor.status) { _, status in
            if status == .online, isFailed {
                Task { await action() }
            }
        }
    }
}

#Preview("Offline") {
    LoadFailureView(
        title: "Can't Load Verse Text",
        error: .network(underlying: URLError(.notConnectedToInternet)),
        offlineMessage: "Connect to the internet to practice.",
        onRetry: {},
        onClose: {},
    )
}

#Preview("Server error") {
    LoadFailureView(
        title: "Can't Load Verse Text",
        error: .http(statusCode: 502, message: nil, data: nil),
        offlineMessage: "Connect to the internet to practice.",
        onRetry: {},
    )
}
