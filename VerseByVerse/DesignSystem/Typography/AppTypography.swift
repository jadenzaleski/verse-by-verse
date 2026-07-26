//
//  AppTypography.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/26/25.
//

import SwiftUI

enum AppTypography {
    case largeTitle, title, title2, title3, headline, subheadline, body, callout, footnote, caption, caption2

    var relative: Font.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption
        case .caption2: .caption2
        }
    }

    var baseSize: CGFloat {
        switch self {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        }
    }
}

private extension Font.Weight {
    /// Montserrat's per-weight PostScript name suffix. Apple's weight names
    /// skew one step lighter than OpenType's weight-class names (Apple's
    /// `.thin` is OpenType "ExtraLight"; Apple's `.ultraLight` is OpenType
    /// "Thin") — this maps to what's actually embedded in the font files.
    var montserratStyleName: String {
        switch self {
        case .ultraLight: "Thin"
        case .thin: "ExtraLight"
        case .light: "Light"
        case .medium: "Medium"
        case .semibold: "SemiBold"
        case .bold: "Bold"
        case .heavy: "ExtraBold"
        case .black: "Black"
        default: "Regular"
        }
    }
}

extension Font {
    static func app(
        _ style: AppTypography = .body,
        size: CGFloat? = nil,
        weight: Font.Weight? = nil,
        italic: Bool = false,
    ) -> Font {
        let resolvedWeight: Font.Weight = weight ?? (style == .headline ? .semibold : .regular)
        let resolvedSize: CGFloat = size ?? style.baseSize
        let styleName = resolvedWeight.montserratStyleName
        // The roman and italic Montserrat files register under the same
        // family name, so weight+italic together only resolve to a single
        // font by naming the exact static instance. The regular-weight
        // italic instance is "Montserrat-Italic", not "Montserrat-RegularItalic".
        let name = italic
            ? (styleName == "Regular" ? "Montserrat-Italic" : "Montserrat-\(styleName)Italic")
            : "Montserrat-\(styleName)"
        return .custom(name, size: resolvedSize, relativeTo: style.relative)
    }

    static func bible(
        _ style: AppTypography = .body,
        size: CGFloat? = nil,
        weight: Font.Weight? = nil,
    ) -> Font {
        let resolvedWeight: Font.Weight = weight ?? (style == .headline ? .semibold : .regular)
        return .system(style.relative, design: .serif, weight: resolvedWeight)
    }
}
