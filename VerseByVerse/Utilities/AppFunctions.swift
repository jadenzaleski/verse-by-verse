//
//  AppFunctions.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import SwiftUI

enum AppFunctions {
    static func versionString() -> String? {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        switch (version, build) {
        case let (version?, build?): return "v\(version) (\(build))"
        case let (version?, nil): return "v\(version)"
        case let (nil, build?): return "(\(build))"
        default: return nil
        }
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
            case .development: .accent
            case .beta: .orange
            case .production: .clear
            }
        }
    }

    /// Resolved from the active build configuration's compilation flags:
    /// `BETA` (Beta config) → beta, else `DEBUG` (Debug config) → development,
    /// else production (Release config).
    static var channel: Channel {
        #if BETA
            return .beta
        #elseif DEBUG
            return .development
        #else
            return .production
        #endif
    }
}
