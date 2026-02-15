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

    static let all: [MeshPalette] = [
        .sunset,
        .ocean,
    ]
}
