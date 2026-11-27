//
//  Appearance.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/25/26.
//

import SwiftUI
import UIKit

/// The built-in accent colors, shown in this order. Each raw value is the
/// name of a color set in `Assets.xcassets/Colors`: edit a color there, and
/// to add a preset, add a color set and a case with its name.
nonisolated enum AccentPreset: String, CaseIterable, Identifiable, Sendable {
    /// The app's own accent and the default. It's also the build setting
    /// `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME`, which iOS uses
    /// before the app sets the window tint.
    case standard = "AccentColor"
    case blue = "Blue"
    case purple = "Purple"
    case green = "Green"
    case orange = "Orange"
    case pink = "Pink"

    var id: String {
        rawValue
    }

    /// The VoiceOver label.
    var name: String {
        self == .standard ? "Default" : rawValue
    }

    var assetName: String {
        "Colors/\(rawValue)"
    }

    var color: Color {
        Color(assetName)
    }
}

/// The user's accent: a preset, or a custom sRGB color. Persisted as a string:
/// the preset's raw value, or `#RRGGBB` for a custom color.
nonisolated enum AccentChoice: Hashable, Sendable {
    case preset(AccentPreset)
    case custom(Color.Resolved)

    static let `default` = Self.preset(.standard)

    init?(rawValue: String) {
        if let preset = AccentPreset(rawValue: rawValue) {
            self = .preset(preset)
        } else if let resolved = Self.resolved(fromHex: rawValue) {
            self = .custom(resolved)
        } else {
            return nil
        }
    }

    /// A custom choice, rounded to what `#RRGGBB` can store so that a choice
    /// equals itself after a save and reload.
    static func custom(quantizing resolved: Color.Resolved) -> Self {
        .custom(Self.resolved(fromHex: hex(of: resolved)) ?? resolved)
    }

    var rawValue: String {
        switch self {
        case let .preset(preset): preset.rawValue
        case let .custom(resolved): Self.hex(of: resolved)
        }
    }

    var color: Color {
        switch self {
        case let .preset(preset): preset.color
        case let .custom(resolved): Color(resolved)
        }
    }

    // MARK: - Hex

    static func hex(of resolved: Color.Resolved) -> String {
        func byte(_ component: Float) -> String {
            let value = Int((min(max(component, 0), 1) * 255).rounded())
            let digits = String(value, radix: 16, uppercase: true)
            return digits.count == 1 ? "0" + digits : digits
        }
        return "#" + byte(resolved.red) + byte(resolved.green) + byte(resolved.blue)
    }

    static func resolved(fromHex hex: String) -> Color.Resolved? {
        guard hex.count == 7, hex.first == "#", let value = UInt32(hex.dropFirst(), radix: 16) else {
            return nil
        }
        return Color.Resolved(
            red: Float((value >> 16) & 0xFF) / 255,
            green: Float((value >> 8) & 0xFF) / 255,
            blue: Float(value & 0xFF) / 255,
        )
    }
}

/// Readability check for custom accents, which keep one color in both
/// appearances. Uses the WCAG 2 contrast ratio with the 3:1 minimum for UI
/// components and large text, against the app's lightest and darkest surfaces.
nonisolated enum AccentContrast {
    static func isHardToReadInLightMode(_ color: Color.Resolved) -> Bool {
        // White: the light-mode card and list-row background.
        contrast(of: color, against: 1.0) < 3
    }

    static func isHardToReadInDarkMode(_ color: Color.Resolved) -> Bool {
        // #1C1C1E (`secondarySystemGroupedBackground`): the dark-mode card background.
        contrast(of: color, against: 0.0116) < 3
    }

    /// WCAG contrast ratio between `color` and a background of the given
    /// relative luminance.
    private static func contrast(of color: Color.Resolved, against background: Double) -> Double {
        func linear(_ component: Float) -> Double {
            Double(min(max(component, 0), 1))
        }
        let luminance = 0.2126 * linear(color.linearRed) + 0.7152 * linear(color.linearGreen)
            + 0.0722 * linear(color.linearBlue)
        return (max(luminance, background) + 0.05) / (min(luminance, background) + 0.05)
    }
}

/// The app's light/dark appearance: iOS's own light or dark mode, or
/// whichever the system is using. No custom palettes: forcing a mode just
/// overrides the window's `overrideUserInterfaceStyle`.
nonisolated enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    /// Declaration order is the picker's segment order.
    case light, system, dark

    var id: String {
        rawValue
    }

    var iconName: String {
        switch self {
        case .light: "lucide.sun"
        case .system: "lucide.sun.moon"
        case .dark: "lucide.moon"
        }
    }

    var name: String {
        rawValue.capitalized
    }

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Holds the user's appearance choices: the accent and the theme.
/// `Color.appAccent` reads `accent`, so any view that draws with the accent
/// redraws when it changes.
@MainActor @Observable
final class AppearanceStore {
    static let shared = AppearanceStore()

    private(set) var accent: AccentChoice
    private(set) var theme: AppTheme

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        accent = defaults.string(forKey: StorageKeys.accentColor.rawValue)
            .flatMap(AccentChoice.init(rawValue:)) ?? .default
        theme = defaults.string(forKey: StorageKeys.theme.rawValue)
            .flatMap(AppTheme.init(rawValue:)) ?? .system
    }

    var accentColor: Color {
        accent.color
    }

    func selectAccent(_ newAccent: AccentChoice) {
        guard newAccent != accent else { return }
        accent = newAccent
        defaults.set(newAccent.rawValue, forKey: StorageKeys.accentColor.rawValue)
    }

    func selectTheme(_ newTheme: AppTheme) {
        guard newTheme != theme else { return }
        theme = newTheme
        defaults.set(newTheme.rawValue, forKey: StorageKeys.theme.rawValue)
    }
}

extension View {
    /// Applies the user's appearance at the root. The accent goes to the
    /// window's `tintColor`, which SwiftUI reads as its default accent and
    /// UIKit-presented UI (alerts, the share sheet) also uses. Not
    /// `.tint()`: an explicit tint also colors Liquid Glass toolbar buttons,
    /// which should stay the primary color. The theme goes to the
    /// window's `overrideUserInterfaceStyle`, which, unlike
    /// `preferredColorScheme`, reliably returns to the system setting and
    /// also reaches UIKit-presented UI.
    func appAppearance() -> some View {
        modifier(AppAppearance())
    }
}

private struct AppAppearance: ViewModifier {
    func body(content: Content) -> some View {
        let store = AppearanceStore.shared
        content
            .background(WindowAppearance(
                tint: UIColor(store.accentColor),
                style: store.theme.userInterfaceStyle,
            ))
    }
}

/// Applies a tint and interface style to the window it's placed in (this
/// scene's window only).
private struct WindowAppearance: UIViewRepresentable {
    let tint: UIColor
    let style: UIUserInterfaceStyle

    func makeUIView(context _: Context) -> WindowConfiguringView {
        let view = WindowConfiguringView()
        view.isUserInteractionEnabled = false
        view.tint = tint
        view.style = style
        return view
    }

    func updateUIView(_ view: WindowConfiguringView, context _: Context) {
        view.tint = tint
        view.style = style
    }

    final class WindowConfiguringView: UIView {
        var tint: UIColor? {
            didSet { apply() }
        }

        var style: UIUserInterfaceStyle = .unspecified {
            didSet { apply() }
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            apply()
        }

        private func apply() {
            guard let window else { return }
            window.tintColor = tint
            window.overrideUserInterfaceStyle = style
        }
    }
}
