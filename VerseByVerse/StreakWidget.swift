//
//  StreakWidget.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/27/25.
//

import SwiftUI

struct StreakWidget: View {
    // Inputs
    private var completed: [Bool]
    private var streakCount: Int
    private let dayLetters: [String] = ["S", "M", "T", "W", "T", "F", "S"]

    // Animation state: one per day
    @State private var revealed: [Bool] = []
    @State private var showBadge: Bool = false
    @State private var revealedDigits: Int = 0

    init(completed: [Bool] = [true, true, true, true, true, true, true], streakCount: Int = 1675) {
        self.completed = completed
        self.streakCount = streakCount
    }

    var body: some View {
        HStack {
            HStack(spacing: 10) {
                ForEach(0..<completed.count, id: \.self) { i in
                    let intensity = (0.4 + Double(i) * 0.1)
                    VStack(alignment: .center, spacing: 1) {
                        Text(dayLetters[i])
                            .font(.app(.footnote, weight: .semibold))
                            .foregroundStyle(.secondary)

                        ZStack {
                            Image(completed[i] ? "lucide.circle.check.fill" : "lucide.circle")
                                .foregroundColor(completed[i] ? .orange : .gray)
                                .font(.app(.title2, weight: .semibold))
                                .scaleEffect(revealed[safe: i] == true ? 1.0 : 0.4)
                                .opacity(revealed[safe: i] == true ? 1.0 : 0.0)
                                .animation(.spring(response: 0.35, dampingFraction: 0.50), value: revealed)
                                .sensoryFeedback(
                                    .impact(
                                        flexibility: .rigid,
                                        intensity: intensity),
                                    trigger: revealed[safe: i] == true && completed[i])

                            // Particle burst when a completed day is revealed
                            if completed[i] && (revealed[safe: i] == true) {
                                ParticleBurst(count: 10, baseColor: .orange, duration: 0.45)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .frame(minWidth: 22)
                }
            }
            Spacer()
            streakBadge()
        }
        .padding(25)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Initialize revealed array to false for each day
                if revealed.count != completed.count {
                    revealed = Array(repeating: false, count: completed.count)
                }
                // Stagger the pop-in for completed days only
                for i in completed.indices {
                    //                guard completed[i] else { continue }
                    let delay = Double(i) * 0.15
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                            if i < revealed.count { revealed[i] = true }
                        }
                    }
                }
                // After all day reveals, show badge then flip digits
                let lastDelay = Double(max(0, completed.count - 1)) * 0.15
                DispatchQueue.main.asyncAfter(deadline: .now() + lastDelay + 0.45) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        showBadge = true
                    }
                    // Sequentially reveal each numeric digit with a small cadence
                    let chars = Array(streakCount.formatted(.number.grouping(.automatic)))
                    let totalDigits = chars.filter { Int(String($0)) != nil }.count
                    revealedDigits = 0
                    for step in 0..<totalDigits {
                        let delay = Double(step) * 0.08
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                revealedDigits = step + 1
                            }
                        }
                    }
                }
            }
        }
        Button("Reset") {
            revealed = []
            showBadge = false
            revealedDigits = 0
        }
        .padding()
    }

    // Animated streak badge: flame appears, then digits flip in sequence
    @ViewBuilder
    private func streakBadge() -> some View {
        let chars = Array(streakCount.formatted(.number.grouping(.automatic)))
        // Build metadata: per character, whether it's a digit, and its order among digits
        var digitOrder = -1
        // swiftlint:disable:next large_tuple
        let items: [(char: String, isDigit: Bool, order: Int?)] = chars.map { character in
            let str = String(character)
            if Int(str) != nil {
                digitOrder += 1
                return (str, true, digitOrder)
            } else {
                return (str, false, nil)
            }
        }

        HStack(spacing: 0) {
            Image("lucide.flame")
                .font(.app(.title, weight: .semibold))
                .rotationEffect(.degrees(showBadge ? 0 : -10))
                .opacity(showBadge ? 1 : 0)
                .scaleEffect(showBadge ? 1.0 : 0.6)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: showBadge)
                .sensoryFeedback(.impact(weight: .light, intensity: 0.3), trigger: revealedDigits)
            ForEach(items.indices, id: \.self) { idx in
                let item = items[idx]
                if item.isDigit, let order = item.order {
                    // Flip-in per digit based on its digit order (ignoring separators)
                    Text(item.char)
                        .font(.app(.title2, weight: .semibold))
                        .opacity(order < revealedDigits ? 1.0 : 0.0)
                        .rotation3DEffect(
                            .degrees(order < revealedDigits ? 0 : -90),
                            axis: (x: 1, y: 0, z: 0),
                            anchor: .bottom,
                            perspective: 0.6
                        )
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: revealedDigits)
                        .sensoryFeedback(.impact(weight: .light, intensity: 0.3), trigger: revealedDigits)
                } else {
                    // Non-digit (e.g., grouping separator) fades with badge, doesn't flip
                    Text(item.char)
                        .font(.app(.title2, weight: .semibold))
                        .opacity(showBadge ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: showBadge)
                }
            }
        }
        .foregroundColor(.orange)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        // Keep the final size from the start by rendering in place
        .overlay(EmptyView())
    }
}

// Safe index helper to avoid out-of-bounds during animation initialization
private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    StreakWidget()
        .environment(\.font, .app())
}
