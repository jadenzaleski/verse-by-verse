//
//  ProfileView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/25/25.
//

import CryptoKit
import Foundation
import SwiftData
import SwiftUI

struct ProfileView: View {
    private let log = AppLog.category("ProfileView")
    private let jitter: Float = 0.5
    @Environment(UserStore.self) private var userStore
    @Query private var passages: [Passage]
    @Query private var sessions: [PracticeSession]

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
            VStack(spacing: 15) {
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
                .scaledToFill()
                .frame(width: 150, height: 150)
                .clipShape(Circle())
                .glassEffect()
                .shadow(color: .black.opacity(0.35), radius: 6, x: 2, y: 2)
                .overlay {
                    Text(initials(firstName: firstName, lastName: lastName))
                        .font(.app(size: 50, weight: .black))
                        .foregroundStyle(.ultraThinMaterial)
                }

                VStack(spacing: AppSpacing.xs) {
                    if let email = user?.email {
                        Text(email)
                            .font(.app(.subheadline))
                            .foregroundStyle(.secondary)
                    }
                    Text(sinceDate)
                        .font(.app(.footnote))
                        .foregroundStyle(.secondary)
                }

                lifetimeStats

                WeeklySessionsChart(sessions: sessions)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
            }
            .padding(.horizontal)
        }
        .navigationTitle("\(firstName) \(lastName)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .toolbarTitleDisplayMode(.large)
        .task {
            await userStore.loadUser()
        }
    }

    // MARK: - Lifetime stats

    @ViewBuilder
    private var lifetimeStats: some View {
        let avgScore = PracticeStats.averageScore(sessions)

        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: AppSpacing.md), GridItem(.flexible())],
            spacing: AppSpacing.md,
        ) {
            statCard(value: "\(passages.count)", label: "Passages", systemImage: "book.closed")
            statCard(value: "\(PracticeStats.completedCount(sessions))",
                     label: "Sessions", systemImage: "checkmark.circle")
            statCard(value: "\(PracticeStats.bestStreak(from: sessions))",
                     label: "Best Streak", systemImage: "flame.fill",
                     valueStyle: AnyShapeStyle(streakGradient))
            statCard(value: avgScore.map { "\(Int($0 * 100))%" } ?? "—",
                     label: "Avg Score", systemImage: "chart.line.uptrend.xyaxis",
                     valueStyle: avgScore.map { AnyShapeStyle(scoreColor($0)) } ?? AnyShapeStyle(.primary))
        }
    }

    private func statCard(
        value: String,
        label: String,
        systemImage: String,
        valueStyle: AnyShapeStyle = AnyShapeStyle(.primary),
    ) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: systemImage)
                .font(.app(.caption))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.app(.title2, weight: .bold))
                .foregroundStyle(valueStyle)
                .contentTransition(.numericText())
            Text(label)
                .font(.app(.caption))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private var streakGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color("CustomPurple"), Color("CustomGreen")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing,
        )
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case ..<0.6: .red
        case ..<0.8: .orange
        default: .green
        }
    }

    /// First letters of each name, safely — empty names contribute nothing.
    private func initials(firstName: String, lastName: String) -> String {
        let first = firstName.first.map(String.init) ?? ""
        let last = lastName.first.map(String.init) ?? ""
        let combined = (first + last).uppercased()
        return combined.isEmpty ? "•" : combined
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
            .modelContainer(PreviewData.container)
            .environment(\.font, .app())
            .environment(UserStore.shared)
    }
}
