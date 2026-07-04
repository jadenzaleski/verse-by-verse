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

    static let all: [MeshPalette] = [
        .sunset,
        .ocean,
        .forest,
    ]
}

extension MeshTheme {
    var palette: MeshPalette {
        switch self {
        case .ocean: .ocean
        case .sunset: .sunset
        case .forest: .forest
        }
    }
}
