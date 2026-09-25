//
//  AppLinks.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 9/23/26.
//

import Foundation

/// The app's outbound links and the support-contact payload.
///
/// Centralized so Settings, any future onboarding, and the App Store listing
/// all point at the same places, and so the support-email body stays testable
/// without having to go through a view. Pure value reads, no UI — safe from
/// any thread, so it opts out of the project's default MainActor isolation.
///
/// - Note: The `URL(string:)` force-unwraps are literals validated by
///   `AppLinksTests`, so a typo fails the test suite rather than shipping.
nonisolated enum AppLinks {
    static let website = URL(string: "https://versebyverse.jadenzaleski.com")!
    static let privacyPolicy = URL(string: "https://versebyverse.jadenzaleski.com/privacy.html")!
    static let supportEmail = "jadenzaleski@icloud.com"
    static let supportSubject = "Verse by Verse support"

    /// Build/OS details appended to a support email so the first reply doesn't
    /// have to be "which version are you on?".
    ///
    /// Deliberately limited to app version, release channel, and OS version —
    /// no device identifier, no hardware model, nothing that could fingerprint
    /// the sender. The app's whole privacy posture is "collects nothing," and
    /// a support form is not the place to start making exceptions.
    static func diagnosticSummary() -> String {
        """
        App: \(AppFunctions.versionString() ?? "unknown")
        Channel: \(AppFunctions.channel)
        OS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        """
    }

    /// Body for a support email: blank space to type in, then the details
    /// below a separator so they survive the user's reply without being the
    /// first thing they see.
    static func supportBody() -> String {
        """


        ---
        Please keep the details below — they help with troubleshooting.
        \(diagnosticSummary())
        """
    }

    /// A `mailto:` URL with the subject and body pre-filled.
    ///
    /// Returns nil only if `supportEmail` can't be encoded into a URL, which
    /// the tests rule out. Whether a *mail client exists to handle it* is a
    /// separate question the caller has to handle — see `SettingsView`.
    static func supportMailto() -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: supportSubject),
            URLQueryItem(name: "body", value: supportBody()),
        ]
        return components.url
    }
}
