//
//  AppLinks.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 9/23/26.
//

import Foundation

/// Outbound links and the support-contact payload.
nonisolated enum AppLinks {
    static let website = URL(string: "https://versebyverse.jadenzaleski.com")!
    static let privacyPolicy = URL(string: "https://versebyverse.jadenzaleski.com/privacy.html")!
    static let github = URL(string: "https://github.com/jadenzaleski/verse-by-verse")!
    static let supportEmail = "jadenzaleski@icloud.com"
    static let supportSubject = "Verse by Verse support"

    static func diagnosticSummary() -> String {
        """
        App: \(AppFunctions.versionString() ?? "unknown")
        Channel: \(AppFunctions.channel)
        OS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        """
    }

    static func supportBody() -> String {
        """


        ---
        Please keep the details below - they help with troubleshooting.
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
