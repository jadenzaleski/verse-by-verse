//
//  AppColor.swift
//  VerseByVerse
//

import SwiftUI

extension Color {
    static let appPurple = Color("CustomPurple")
    static let appGreen = Color("CustomGreen")
    /// The user's accent (Settings → Appearance), blue by default. Read it
    /// in a view's body so the view redraws when the user changes it.
    static var appAccent: Color {
        AppearanceStore.shared.accentColor
    }

    // Status
    static let appDestructive = Color.red
    static let appSuccess = Color.green
    static let appPrimary = Color.primary

    /// The one colour rule for any percentage in the app (Memory Score, practice
    /// results, averages): red below 60%, orange below 80%, green from 80%.
    /// ``ScoreBand`` holds the boundaries, for views that must place them
    /// (the chart line's gradient).
    nonisolated static func score(_ value: Double) -> Color {
        switch value {
        case ..<ScoreBand.orange: .red
        case ..<ScoreBand.green: .orange
        default: .green
        }
    }
}

/// Where each score colour starts, as a 0…1 score.
nonisolated enum ScoreBand {
    static let orange = 0.6
    static let green = 0.8
}
