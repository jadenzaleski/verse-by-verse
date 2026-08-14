//
//  ButtonStyles.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 8/10/26.
//

import SwiftUI

/// The full-width filled button used for a screen's primary action.
/// Carries the app's own tokens (Montserrat via `.app()`, `AppRadius.md`)
/// rather than the system's, so it sits alongside the rest of the UI
/// instead of introducing a second visual language.
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .appAccent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.app(.body, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppRadius.md)
            .background(color, in: RoundedRectangle(cornerRadius: AppRadius.md))
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// The outlined counterpart to `PrimaryButtonStyle`, for a secondary action
/// sitting beside a primary one.
struct OutlinedButtonStyle: ButtonStyle {
    var color: Color = .appAccent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.app(.body, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppRadius.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(color.opacity(0.5), lineWidth: 1.5),
            )
            .foregroundStyle(color)
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle {
        .init()
    }

    /// A primary button in a different tint — e.g. destructive for "Done"
    /// while recording.
    static func primary(_ color: Color) -> PrimaryButtonStyle {
        .init(color: color)
    }
}

extension ButtonStyle where Self == OutlinedButtonStyle {
    static var outlined: OutlinedButtonStyle {
        .init()
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        Button("Start") {}
            .buttonStyle(.primary)
        Button("Done") {}
            .buttonStyle(.primary(.appDestructive))
        Button("Skip") {}
            .buttonStyle(.outlined)
        HStack(spacing: AppSpacing.md) {
            Button("Start") {}
                .buttonStyle(.primary)
            Button("Skip") {}
                .buttonStyle(.outlined)
        }
    }
    .padding(AppSpacing.xl)
    .environment(\.font, .app())
}
