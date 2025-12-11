//
//  Font.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/26/25.
//

import SwiftUI

enum AppFontStyle {
    case largeTitle, title, title2, title3, headline, subheadline, body, callout, footnote, caption, caption2

    var relative: Font.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption
        case .caption2: return .caption2
        }
    }

    var baseSize: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        }
    }
}

extension Font {
    static func app(
        _ style: AppFontStyle = .body,
        weight: Font.Weight? = nil,
        italic: Bool = false
    ) -> Font {
        let name = "Montserrat"
        let resolvedWeight: Font.Weight = weight ?? (style == .headline ? .semibold : .regular)
        return .custom(name, size: style.baseSize, relativeTo: style.relative).italic(italic).weight(resolvedWeight)
    }
}
