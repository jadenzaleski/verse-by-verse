//
//  AppearanceTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 11/25/26.
//

import Foundation
import SwiftUI
import Testing
import UIKit
@testable import VerseByVerse

@Suite("Appearance") @MainActor
struct AppearanceTests {
    // MARK: - Persistence format

    @Test func `presets round-trip through their raw value`() {
        for preset in AccentPreset.allCases {
            let choice = AccentChoice.preset(preset)
            #expect(AccentChoice(rawValue: choice.rawValue) == choice)
        }
    }

    @Test func `custom colors store as uppercase hex and round-trip`() {
        let choice = AccentChoice.custom(quantizing: Color.Resolved(red: 1, green: 0.5, blue: 0))
        #expect(choice.rawValue == "#FF8000")
        #expect(AccentChoice(rawValue: choice.rawValue) == choice)
    }

    @Test func `out-of-range components are clamped`() {
        let resolved = Color.Resolved(colorSpace: .sRGBLinear, red: 2, green: -1, blue: 0.5)
        #expect(AccentChoice.hex(of: resolved).hasPrefix("#FF00"))
    }

    @Test(arguments: ["", "nope", "#12345", "#1234567", "FF8000", "#GG0000"])
    func `malformed raw values are rejected`(raw: String) {
        #expect(AccentChoice(rawValue: raw) == nil)
    }

    @Test func `every preset has a color set in the asset catalog`() {
        for preset in AccentPreset.allCases {
            #expect(UIColor(named: preset.assetName) != nil, "\(preset.assetName) is missing from Assets.xcassets")
        }
    }

    // MARK: - Store

    @Test func `the store defaults to blue and persists a selection`() throws {
        let suite = "AppearanceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        #expect(AppearanceStore(defaults: defaults).accent == .default)

        AppearanceStore(defaults: defaults).selectAccent(.preset(.teal))
        #expect(AppearanceStore(defaults: defaults).accent == .preset(.teal))

        let custom = AccentChoice.custom(quantizing: Color.Resolved(red: 0.2, green: 0.4, blue: 0.6))
        AppearanceStore(defaults: defaults).selectAccent(custom)
        #expect(AppearanceStore(defaults: defaults).accent == custom)
    }

    @Test func `an unreadable stored value falls back to the default`() throws {
        let suite = "AppearanceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("garbage", forKey: StorageKeys.accentColor.rawValue)

        #expect(AppearanceStore(defaults: defaults).accent == .default)
    }

    // MARK: - Contrast

    @Test func `the default blue reads well in both modes`() throws {
        let blue = try #require(AccentChoice.resolved(fromHex: "#007AFF"))
        #expect(AppearanceView.contrastWarning(for: blue, theme: .system) == nil)
    }

    @Test func `yellow is flagged for light mode`() throws {
        let yellow = try #require(AccentChoice.resolved(fromHex: "#FFFF00"))
        #expect(AccentContrast.isHardToReadInLightMode(yellow))
        #expect(!AccentContrast.isHardToReadInDarkMode(yellow))
    }

    @Test func `navy is flagged for dark mode`() throws {
        let navy = try #require(AccentChoice.resolved(fromHex: "#000080"))
        #expect(!AccentContrast.isHardToReadInLightMode(navy))
        #expect(AccentContrast.isHardToReadInDarkMode(navy))
    }

    @Test func `mid gray passes on white but pale gray does not`() throws {
        let gray = try #require(AccentChoice.resolved(fromHex: "#767676")) // ~4.5:1 on white
        #expect(!AccentContrast.isHardToReadInLightMode(gray))
        let pale = try #require(AccentChoice.resolved(fromHex: "#A0A0A0")) // ~2.6:1 on white
        #expect(AccentContrast.isHardToReadInLightMode(pale))
    }

    // MARK: - Theme

    @Test func `the theme defaults to system and persists a selection`() throws {
        let suite = "AppearanceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        #expect(AppearanceStore(defaults: defaults).theme == .system)

        AppearanceStore(defaults: defaults).selectTheme(.dark)
        #expect(AppearanceStore(defaults: defaults).theme == .dark)

        defaults.set("sepia", forKey: StorageKeys.theme.rawValue)
        #expect(AppearanceStore(defaults: defaults).theme == .system)
    }

    @Test func `themes are ordered light, system, dark with matching icons`() {
        #expect(AppTheme.allCases == [.light, .system, .dark])
        #expect(AppTheme.allCases.map(\.iconName) == ["lucide.sun", "lucide.sun.moon", "lucide.moon"])
        for theme in AppTheme.allCases {
            #expect(UIImage(named: theme.iconName) != nil, "\(theme.iconName) is missing from Assets.xcassets")
        }
    }

    @Test func `themes map to the window interface style`() {
        #expect(AppTheme.system.userInterfaceStyle == .unspecified)
        #expect(AppTheme.light.userInterfaceStyle == .light)
        #expect(AppTheme.dark.userInterfaceStyle == .dark)
    }

    @Test func `the contrast warning only checks the modes the theme shows`() throws {
        let yellow = try #require(AccentChoice.resolved(fromHex: "#FFFF00")) // fails on white only
        #expect(AppearanceView.contrastWarning(for: yellow, theme: .system) != nil)
        #expect(AppearanceView.contrastWarning(for: yellow, theme: .light) != nil)
        #expect(AppearanceView.contrastWarning(for: yellow, theme: .dark) == nil)

        let navy = try #require(AccentChoice.resolved(fromHex: "#000080")) // fails on dark only
        #expect(AppearanceView.contrastWarning(for: navy, theme: .light) == nil)
        #expect(AppearanceView.contrastWarning(for: navy, theme: .dark) != nil)
    }
}
