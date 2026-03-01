//
//  ProfileView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/25/25.
//

import CryptoKit
import Foundation
import SwiftUI

struct ProfileView: View {
    private let log = AppLog.category("ProfileView")
    private let jitter: Float = 0.5
    @Environment(UserStore.self) private var userStore

    var body: some View {
        let user = userStore.currentUser
        let firstName = user?.firstName ?? "Unknown"
        let lastName = user?.lastName ?? "User"
        let sinceDate = "Since " + (user?.createdAt?.formatted(date: .long, time: .omitted) ?? " an unknown date")
        let userIdInt: Int = user?.id.stableSeed ?? 12345
        var themeGenerator = SeededGenerator(seed: userIdInt)

        // Row 1
        // p0
        let p0Position: SIMD2<Float> = [0.0, 0.0]
        let p0LeadingControlPoint: SIMD2<Float> = [0.0, 0.0]
        let p0TopControlPoint: SIMD2<Float> = [0.0, 0.0]
        let p0TrailingControlPoint: SIMD2<Float> = [jitteredNumber(0.5, userIdInt), 0.0]
        let p0BottomControlPoint: SIMD2<Float> = [0.0, jitteredNumber(0.5, userIdInt)]
        // p1
        let p1Position: SIMD2<Float> = [1.0, 0.0]
        let p1LeadingControlPoint: SIMD2<Float> = [jitteredNumber(0.5, userIdInt), 0.0]
        let p1TopControlPoint: SIMD2<Float> = [1.0, 0.0]
        let p1TrailingControlPoint: SIMD2<Float> = [1.0, 0.0]
        let p1BottomControlPoint: SIMD2<Float> = [1.0, jitteredNumber(0.5, userIdInt)]
        // Row 2
        // p2
        let p2Position: SIMD2<Float> = [0.0, 1.0]
        let p2LeadingControlPoint: SIMD2<Float> = [0.0, 1.0]
        let p2TopControlPoint: SIMD2<Float> = [0.0, jitteredNumber(0.5, userIdInt)]
        let p2TrailingControlPoint: SIMD2<Float> = [jitteredNumber(0.5, userIdInt), 1.0]
        let p2BottomControlPoint: SIMD2<Float> = [0.0, 1.0]
        // p3
        let p3Position: SIMD2<Float> = [1.0, 1.0]
        let p3LeadingControlPoint: SIMD2<Float> = [jitteredNumber(0.5, userIdInt), 1.0]
        let p3TopControlPoint: SIMD2<Float> = [1.0, jitteredNumber(0.5, userIdInt)]
        let p3TrailingControlPoint: SIMD2<Float> = [1.0, 1.0]
        let p3BottomControlPoint: SIMD2<Float> = [1.0, 1.0]

        ScrollView {
            MeshGradient(
                width: 2,
                height: 2,
                bezierPoints: [
                    // Row 1 (top)
                    // p0
                    MeshGradient.BezierPoint(
                        position: p0Position,
                        leadingControlPoint: p0LeadingControlPoint,
                        topControlPoint: p0TopControlPoint,
                        trailingControlPoint: p0TrailingControlPoint,
                        bottomControlPoint: p0BottomControlPoint,
                    ),
                    // p1
                    MeshGradient.BezierPoint(
                        position: p1Position,
                        leadingControlPoint: p1LeadingControlPoint,
                        topControlPoint: p1TopControlPoint,
                        trailingControlPoint: p1TrailingControlPoint,
                        bottomControlPoint: p1BottomControlPoint,
                    ),
                    // Row 2 (bottom)
                    // p2
                    MeshGradient.BezierPoint(
                        position: p2Position,
                        leadingControlPoint: p2LeadingControlPoint,
                        topControlPoint: p2TopControlPoint,
                        trailingControlPoint: p2TrailingControlPoint,
                        bottomControlPoint: p2BottomControlPoint,
                    ),

                    // p3
                    MeshGradient.BezierPoint(
                        position: p3Position,
                        leadingControlPoint: p3LeadingControlPoint,
                        topControlPoint: p3TopControlPoint,
                        trailingControlPoint: p3TrailingControlPoint,
                        bottomControlPoint: p3BottomControlPoint,
                    ),
                ],
                colors: shuffledColors(from: MeshPalette.all.randomElement(using: &themeGenerator)
                    ?? .ocean, seed: userIdInt),
            )
//                .resizable()
            .scaledToFill()
            .frame(width: 150, height: 150)
            .clipShape(Circle())
            .glassEffect()
            .shadow(color: .black.opacity(0.35), radius: 6, x: 2, y: 2)
            .padding(20)
            .overlay {
                Text(firstName.first!.uppercased() + lastName.first!.uppercased())
                    .font(.app(size: 50, weight: .black))
                    .foregroundStyle(.ultraThinMaterial)
            }

            Text(sinceDate)
                .font(.app(.footnote))
                .foregroundStyle(.secondary)

            HStack(spacing: 60) {
                VStack {
                    Text("123")
                        .font(.app(.body, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("CustomPurple"), Color("CustomGreen")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing,
                            ),
                        )
                    Text("Best Streak")
                        .font(.app(.footnote))
                }

                VStack {
                    Text("456")
                        .font(.app(.body, weight: .bold))
                    Text("Passages")
                        .font(.app(.footnote))
                }
            }
            .padding(10)
            Spacer()
        }
        .navigationTitle("\(firstName) \(lastName)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image("lucide.settings")
                }
            }
        }
        .toolbarTitleDisplayMode(.inlineLarge)
        .task {
            await userStore.loadUser()
        }
    }

    private func jitteredNumber(_ number: Float, _ seed: Int) -> Float {
        var generator = SeededGenerator(seed: seed)
        // set min and max to ensure our result cannot be out of bounds [0.0, 1.0]
        let minBound = max(0.0, number - jitter)
        let maxBound = min(1.0, number + jitter)
        return Float.random(in: minBound ... maxBound, using: &generator)
    }

    private func shuffledColors(from palette: MeshPalette, seed: Int) -> [Color] {
        var generator = SeededGenerator(seed: seed)
        var colors = palette.colors

        colors.shuffle(using: &generator)
        return colors
    }
}

extension String {
    var stableSeed: Int {
        // 1. Convert string to data using UTF-8 encoding
        let data = Data(utf8)
        // 2. Generate a SHA-256 hash (32 bytes / 256 bits)
        let hash = SHA256.hash(data: data)
        // 3. Extract the first 8 bytes (64 bits)
        return hash.withUnsafeBytes { pointer in
            pointer.load(as: Int.self)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environment(\.font, .app())
    }
}
