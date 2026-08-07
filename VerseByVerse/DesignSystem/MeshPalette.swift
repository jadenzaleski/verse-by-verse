//
//  MeshPalette.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 2/14/26.
//

import SwiftUI

struct MeshPalette {
    let id: String
    let colors: [Color] // must be 9
}

extension MeshPalette {
    static let sunset = MeshPalette(
        id: "sunset",
        colors: [
            .orange, .pink, .purple,
            .pink, .red, .purple,
            .yellow, .orange, .red,
        ],
    )

    static let ocean = MeshPalette(
        id: "ocean",
        colors: [
            .cyan, .blue, .indigo,
            .blue, .teal, .indigo,
            .mint, .blue, .purple,
        ],
    )

    static let forest = MeshPalette(
        id: "forest",
        colors: [
            .green, .mint, Color(red: 0.2, green: 0.5, blue: 0.2),
            Color(red: 0.1, green: 0.4, blue: 0.1), .green, .teal,
            Color(red: 0.3, green: 0.6, blue: 0.1), Color(red: 0.0, green: 0.5, blue: 0.3), .mint,
        ],
    )

    /// Color Hunt: https://colorhunt.co/palette/222831393e4600adb5eeeeee
    static let slate = MeshPalette(
        id: "slate",
        colors: [
            Color(red: 0.1333, green: 0.1569, blue: 0.1922), // #222831 Charcoal
            Color(red: 0.1333, green: 0.1569, blue: 0.1922), // #222831 Charcoal
            Color(red: 0.0, green: 0.6784, blue: 0.7098), // #00ADB5 Teal
            Color(red: 0.9333, green: 0.9333, blue: 0.9333), // #EEEEEE White Smoke
            Color(red: 0.1333, green: 0.1569, blue: 0.1922), // #222831 Charcoal
            Color(red: 0.2235, green: 0.2431, blue: 0.2745), // #393E46 Slate Gray
            Color(red: 0.1333, green: 0.1569, blue: 0.1922), // #222831 Charcoal
            Color(red: 0.9333, green: 0.9333, blue: 0.9333), // #EEEEEE White Smoke
            Color(red: 0.0, green: 0.6784, blue: 0.7098), // #00ADB5 Teal
        ],
    )

    /// Color Hunt: https://colorhunt.co/palette/fff5e4ffe3e1ffd1d1ff9494
    static let blush = MeshPalette(
        id: "blush",
        colors: [
            Color(red: 1.0, green: 0.9608, blue: 0.8941), // #FFF5E4 Cream
            Color(red: 1.0, green: 0.9608, blue: 0.8941), // #FFF5E4 Cream
            Color(red: 1.0, green: 0.8196, blue: 0.8196), // #FFD1D1 Pink
            Color(red: 1.0, green: 0.5804, blue: 0.5804), // #FF9494 Salmon
            Color(red: 1.0, green: 0.9608, blue: 0.8941), // #FFF5E4 Cream
            Color(red: 1.0, green: 0.8902, blue: 0.8824), // #FFE3E1 Blush
            Color(red: 1.0, green: 0.9608, blue: 0.8941), // #FFF5E4 Cream
            Color(red: 1.0, green: 0.5804, blue: 0.5804), // #FF9494 Salmon
            Color(red: 1.0, green: 0.8196, blue: 0.8196), // #FFD1D1 Pink
        ],
    )

    /// Color Hunt: https://colorhunt.co/palette/f67280c06c846c5b7b355c7d
    static let twilight = MeshPalette(
        id: "twilight",
        colors: [
            Color(red: 0.9647, green: 0.4471, blue: 0.5020), // #F67280 Coral
            Color(red: 0.9647, green: 0.4471, blue: 0.5020), // #F67280 Coral
            Color(red: 0.4235, green: 0.3569, blue: 0.4824), // #6C5B7B Plum
            Color(red: 0.2078, green: 0.3608, blue: 0.4902), // #355C7D Steel Blue
            Color(red: 0.9647, green: 0.4471, blue: 0.5020), // #F67280 Coral
            Color(red: 0.7529, green: 0.4235, blue: 0.5176), // #C06C84 Mauve
            Color(red: 0.9647, green: 0.4471, blue: 0.5020), // #F67280 Coral
            Color(red: 0.2078, green: 0.3608, blue: 0.4902), // #355C7D Steel Blue
            Color(red: 0.4235, green: 0.3569, blue: 0.4824), // #6C5B7B Plum
        ],
    )

    static let all: [MeshPalette] = [
        .sunset,
        .ocean,
        .forest,
        .slate,
        .blush,
        .twilight,
    ]
}

extension MeshTheme {
    var palette: MeshPalette {
        switch self {
        case .ocean: .ocean
        case .sunset: .sunset
        case .forest: .forest
        case .slate: .slate
        case .blush: .blush
        case .twilight: .twilight
        }
    }
}
