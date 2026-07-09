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
    @AppStorage(.displayName) private var displayName = ""
    @Query private var passages: [Passage]
    @Query private var sessions: [PracticeSession]

    private var sinceDate: String? {
        let earliest = passages.map(\.createdAt).min()
        return earliest.map { "Memorizing since \($0.formatted(date: .long, time: .omitted))" }
    }

    /// Seed for the avatar mesh — stable per display name so the gradient
    /// doesn't reshuffle every launch.
    private var avatarSeed: Int {
        displayName.isEmpty ? 12345 : displayName.stableSeed
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                avatar

                if let sinceDate {
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
        .navigationTitle(displayName.isEmpty ? "Your Profile" : displayName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gear")
                }
                .accessibilityLabel("Settings")
            }
        }
        .toolbarTitleDisplayMode(.large)
    }

    // MARK: - Avatar

    private var avatar: some View {
        var themeGenerator = SeededGenerator(seed: avatarSeed)
        let point = { (x: Float, y: Float) -> SIMD2<Float> in [x, y] }

        return MeshGradient(
            width: 2,
            height: 2,
            bezierPoints: [
                MeshGradient.BezierPoint(
                    position: point(0, 0),
                    leadingControlPoint: point(0, 0),
                    topControlPoint: point(0, 0),
                    trailingControlPoint: point(jitteredNumber(0.5, avatarSeed), 0),
                    bottomControlPoint: point(0, jitteredNumber(0.5, avatarSeed)),
                ),
                MeshGradient.BezierPoint(
                    position: point(1, 0),
                    leadingControlPoint: point(jitteredNumber(0.5, avatarSeed), 0),
                    topControlPoint: point(1, 0),
                    trailingControlPoint: point(1, 0),
                    bottomControlPoint: point(1, jitteredNumber(0.5, avatarSeed)),
                ),
                MeshGradient.BezierPoint(
                    position: point(0, 1),
                    leadingControlPoint: point(0, 1),
                    topControlPoint: point(0, jitteredNumber(0.5, avatarSeed)),
                    trailingControlPoint: point(jitteredNumber(0.5, avatarSeed), 1),
                    bottomControlPoint: point(0, 1),
                ),
                MeshGradient.BezierPoint(
                    position: point(1, 1),
                    leadingControlPoint: point(jitteredNumber(0.5, avatarSeed), 1),
                    topControlPoint: point(1, jitteredNumber(0.5, avatarSeed)),
                    trailingControlPoint: point(1, 1),
                    bottomControlPoint: point(1, 1),
                ),
            ],
            colors: shuffledColors(
                from: MeshPalette.all.randomElement(using: &themeGenerator) ?? .ocean,
                seed: avatarSeed,
            ),
        )
        .scaledToFill()
        .frame(width: 150, height: 150)
        .clipShape(Circle())
        .glassEffect()
        .shadow(color: .black.opacity(0.35), radius: 6, x: 2, y: 2)
        .overlay {
            if !displayName.isEmpty {
                Text(initials)
                    .font(.app(size: 50, weight: .black))
                    .foregroundStyle(.ultraThinMaterial)
            }
        }
        .accessibilityHidden(true)
    }

    /// First letters of up to two words of the display name, safely.
    private var initials: String {
        let words = displayName.split(separator: " ").prefix(2)
        let letters = words.compactMap(\.first).map(String.init).joined().uppercased()
        return letters.isEmpty ? "•" : letters
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
    }
}
