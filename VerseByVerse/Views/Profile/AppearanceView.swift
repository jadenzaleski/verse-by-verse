//
//  AppearanceView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/25/26.
//

import SwiftUI

/// Settings → Appearance: the theme (System, Light or Dark), then the accent:
/// a preset swatch or any color from the system color picker. Custom colors
/// that read poorly in the mode(s) the user will see get a warning.
struct AppearanceView: View {
    @Environment(\.self) private var environment

    private let store = AppearanceStore.shared
    private let columns = [GridItem(.adaptive(minimum: 44), spacing: AppSpacing.lg)]

    var body: some View {
        List {
            themeSection
            presetsSection

            Section {
                ColorPicker(selection: customColor, supportsOpacity: false) {
                    Label("Custom Color", image: "lucide.palette")
                }
            } footer: {
                customFooter
            }

            if store.accent != .default {
                Section {
                    Button("Reset Accent Color") {
                        store.selectAccent(.default)
                    }
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Theme

    private var themeSection: some View {
        Section {
            Picker("Theme", selection: theme) {
                ForEach(AppTheme.allCases) { theme in
                    Image(theme.iconName)
                        .accessibilityLabel(theme.name)
                        .tag(theme)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        } header: {
            Text("THEME")
                .font(Font.app(.footnote, weight: .semibold))
        } footer: {
            Text("Light, System or Dark. System follows your iPhone's Light or Dark setting.")
                .font(.app(.caption2))
        }
    }

    private var theme: Binding<AppTheme> {
        Binding {
            store.theme
        } set: { newTheme in
            store.selectTheme(newTheme)
        }
    }

    // MARK: - Accent

    private var presetsSection: some View {
        Section {
            LazyVGrid(columns: columns, spacing: AppSpacing.lg) {
                ForEach(AccentPreset.allCases) { preset in
                    swatch(for: preset)
                }
            }
            .padding(.vertical, AppSpacing.sm)
        } header: {
            Text("ACCENT COLOR")
                .font(Font.app(.footnote, weight: .semibold))
        }
    }

    private func swatch(for preset: AccentPreset) -> some View {
        let isSelected = store.accent == .preset(preset)
        return Button {
            store.selectAccent(.preset(preset))
        } label: {
            Circle()
                .fill(preset.color)
                .frame(width: 36, height: 36)
                .overlay {
                    if isSelected {
                        Image("lucide.check")
                            .foregroundStyle(.white)
                            .font(.app(.subheadline, weight: .bold))
                    }
                }
                .padding(AppSpacing.xxs)
                .overlay {
                    Circle().stroke(isSelected ? preset.color : .clear, lineWidth: 2)
                }
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(preset.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The color picker's binding. Shows the current accent; picking a color
    /// stores it as a custom choice.
    private var customColor: Binding<Color> {
        Binding {
            store.accentColor
        } set: { newColor in
            store.selectAccent(.custom(quantizing: newColor.resolve(in: environment)))
        }
    }

    @ViewBuilder private var customFooter: some View {
        if case let .custom(resolved) = store.accent,
           let warning = Self.contrastWarning(for: resolved, theme: store.theme)
        {
            Label {
                Text(warning)
            } icon: {
                Image("lucide.triangle.exclamation.point")
            }
            .font(.app(.caption2))
            .foregroundStyle(.orange)
        }
    }

    /// Checks only the modes the user can see: both for System, otherwise
    /// just the forced one.
    static func contrastWarning(for color: Color.Resolved, theme: AppTheme) -> String? {
        let light = theme != .dark && AccentContrast.isHardToReadInLightMode(color)
        let dark = theme != .light && AccentContrast.isHardToReadInDarkMode(color)
        switch (light, dark) {
        case (true, true): return "This color may be hard to read in light and dark mode."
        case (true, false): return "This color may be hard to read in light mode."
        case (false, true): return "This color may be hard to read in dark mode."
        case (false, false): return nil
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceView()
    }
    .appAppearance()
    .environment(\.font, .app())
}
