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

extension Font {
    static func app(
        _ style: AppFontStyle = .body,
        size: CGFloat? = nil,
        weight: Font.Weight? = nil,
        italic: Bool = false
    ) -> Font {
        let name = "Montserrat"
        let resolvedWeight: Font.Weight = weight ?? (style == .headline ? .semibold : .regular)
        let resolvedSize: CGFloat = size ?? style.baseSize
        return .custom(name, size: resolvedSize, relativeTo: style.relative).italic(italic).weight(resolvedWeight)
    }
}

