//
//  AppLinksTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 9/23/26.
//

import Foundation
import Testing
@testable import VerseByVerse

/// Pins the outbound links and the support-email payload. `AppLinks` force-
/// unwraps its `URL(string:)` literals, so these tests are what make that
/// safe — a typo in a URL fails here instead of shipping a dead Settings row.
@Suite("App links")
struct AppLinksTests {
    // MARK: - URL literals

    @Test func `website and privacy policy are valid https URLs`() {
        for url in [AppLinks.website, AppLinks.privacyPolicy] {
            #expect(url.scheme == "https")
            #expect(url.host() == "versebyverse.jadenzaleski.com")
        }
    }

    @Test func `privacy policy points at the published page`() {
        #expect(AppLinks.privacyPolicy.path() == "/privacy.html")
    }

    // MARK: - Support email

    @Test func `support email looks like an address`() {
        let parts = AppLinks.supportEmail.split(separator: "@")
        #expect(parts.count == 2)
        #expect(!parts[0].isEmpty)
        #expect(parts[1].contains("."))
        #expect(!AppLinks.supportEmail.contains(" "))
    }

    @Test func `mailto URL carries the address, subject, and body`() throws {
        let url = try #require(AppLinks.supportMailto())
        #expect(url.scheme == "mailto")

        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == AppLinks.supportEmail)

        let queryItems = try #require(components.queryItems)
        let subject = queryItems.first { $0.name == "subject" }?.value
        let body = queryItems.first { $0.name == "body" }?.value
        #expect(subject == AppLinks.supportSubject)
        #expect(body == AppLinks.supportBody())
    }

    @Test func `mailto URL percent-encodes the multiline body`() throws {
        let url = try #require(AppLinks.supportMailto())
        // Raw newlines in a URL would make it unopenable; they must be escaped.
        #expect(!url.absoluteString.contains("\n"))
        #expect(url.absoluteString.contains("%0A"))
    }

    // MARK: - Diagnostics payload

    @Test func `diagnostic summary reports version, channel, and OS`() {
        let summary = AppLinks.diagnosticSummary()
        #expect(summary.contains("App:"))
        #expect(summary.contains("Channel:"))
        #expect(summary.contains("OS:"))
        // Three labelled lines, one per field.
        #expect(summary.split(separator: "\n").count == 3)
    }

    /// The app's privacy policy promises no device or user identifiers leave
    /// the device. A support email is still an outbound payload, so this
    /// guards against a hardware identifier being added to it later.
    @Test func `diagnostic summary carries no device identifier`() {
        let summary = AppLinks.diagnosticSummary().lowercased()
        for forbidden in ["identifierforvendor", "udid", "serial", "hw.machine", "deviceid"] {
            #expect(!summary.contains(forbidden))
        }
    }

    @Test func `support body keeps the details below a separator`() {
        let body = AppLinks.supportBody()
        let separatorIndex = try? #require(body.range(of: "---"))
        #expect(separatorIndex != nil)
        // The user's typing space comes first, details after.
        let detailsRange = try? #require(body.range(of: "App:"))
        if let separatorIndex, let detailsRange {
            #expect(separatorIndex.upperBound <= detailsRange.lowerBound)
        }
    }
}
