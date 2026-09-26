//
//  AppFunctions.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import SwiftUI
import os

/// Pure build/bundle info reads, no UI — safe to call from any thread, so it
/// opts out of the project's default MainActor isolation.
nonisolated enum AppFunctions {
    /// The API base URL for this build, resolved at compile time from the active
    /// build configuration's `API_BASE_URL` xcconfig setting (injected via Info.plist).
    /// Logs via the raw `os.Logger` (not `AppLog`, which is MainActor-isolated)
    /// since this type must stay callable from any thread.
    static let apiBaseURL: URL = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              let url = URL(string: raw)
        else {
            Logger(subsystem: "com.jadenzaleski.vbv", category: "AppFunctions")
                .fault("API_BASE_URL missing or invalid in Info.plist; falling back to an unreachable host.")
            return URL(string: "https://api.invalid")!
        }
        return url
    }()

    /// Dev builds show the commit SHA, beta/production builds show the release
    /// tag — both trace a running build straight back to the exact source
    /// without exposing a clickable GitHub link. Falls back to the marketing
    /// version when git metadata isn't available (e.g. local builds not
    /// stamped by `ci_scripts/ci_pre_xcodebuild.sh`). Build number is always
    /// appended, unaffected by this.
    static func versionString() -> String? {
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        guard let build else { return versionLabel }
        return "\(versionLabel) (\(build))"
    }

    private static var versionLabel: String {
        switch channel {
        case .development:
            if let commit = gitCommit { return String(commit.prefix(7)) }
        case .beta, .production:
            if let tag = gitTag { return tag }
        }
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "v\(version)"
        }
        return "—"
    }

    /// Full commit SHA this build was compiled from, stamped by
    /// `ci_scripts/ci_pre_xcodebuild.sh`. `nil` outside CI (local/preview builds).
    static var gitCommit: String? {
        guard let commit = Bundle.main.infoDictionary?["GitCommit"] as? String, !commit.isEmpty else { return nil }
        return commit
    }

    /// Git tag this build was cut from, when it was triggered by a tag push
    /// (release/beta builds) rather than a plain branch push (dev builds).
    static var gitTag: String? {
        guard let tag = Bundle.main.infoDictionary?["GitTag"] as? String, !tag.isEmpty else { return nil }
        return tag
    }

    /// Distribution channel of the running build, resolved at compile time from
    /// the active build configuration.
    enum Channel {
        case development, beta, production

        /// Short label for the build badge, or `nil` in production (no badge shown).
        var badge: String? {
            switch self {
            case .development: "DEV"
            case .beta: "BETA"
            case .production: nil
            }
        }

        /// Tint for the build badge.
        var badgeColor: Color {
            switch self {
            case .development: .accentColor
            case .beta: .orange
            case .production: .clear
            }
        }
    }

    /// The single Release-scheme Xcode Cloud workflow archives every tag
    /// (`vX.Y.Z-beta.N` and `vX.Y.Z` alike), so `ci_pre_xcodebuild.sh` stamps
    /// the real channel into Info.plist per-tag — that value wins when present.
    /// Local builds (no CI script run) fall back to the compile-time flags:
    /// `BETA` (Beta scheme) → beta, `DEBUG` (Debug scheme) → development, else
    /// production (Release scheme).
    static var channel: Channel {
        switch Bundle.main.infoDictionary?["BuildChannel"] as? String {
        case "beta": return .beta
        case "production": return .production
        default: break
        }
        #if BETA
            return .beta
        #elseif DEBUG
            return .development
        #else
            return .production
        #endif
    }
}
