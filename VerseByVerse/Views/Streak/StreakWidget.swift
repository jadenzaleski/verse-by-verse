//
//  StreakWidget.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/27/25.
//

import os
import SwiftUI

struct StreakWidget: View {
    // Inputs
    private var completed: [Bool]
    private var streakCount: Int

    private let dayLetters: [String] = ["S", "M", "T", "W", "T", "F", "S"]
    private let dayDelaySeconds: Double = 0.1
    private let startAnimationDelaySeconds: Double = 0.75
    private let todaysDateInt: Int = Calendar.current.component(.weekday, from: Date())
    private let log = AppLog.category("StreakWidget")

    // Animation state: one per day
    @State private var revealed: [Bool] = []
    @State private var showBadge: Bool = false
    @State private var revealedDigits: Int = 0
    @State private var drawTodayStroke: CGFloat = 0

    init(completed: [Bool] = [false, false, false, false, false, false, false], streakCount: Int = 0) {
        self.completed = completed
        self.streakCount = streakCount
    }

    var body: some View {
        HStack {
            HStack(spacing: 0) {
                // Display each day
                ForEach(0 ..< completed.count, id: \.self) { i in
                    // The instensity will build so we calculate that
                    let intensity = (0.4 + Double(i) * 0.1)
                    VStack(alignment: .center, spacing: 1) {
                        // Show the day letters
                        Text(dayLetters[i])
                            .font(.app(.footnote, weight: .semibold))
                            .foregroundStyle(.secondary)
                        ZStack {
                            Image(completed[i] ? "lucide.circle.check.fill" : "lucide.circle")
                                .foregroundColor(completed[i] ? .orange : .secondary)
                                .font(.app(.title2, weight: .semibold))
                                .scaleEffect(revealed[safe: i] == true ? 1.0 : 0.4)
                                .opacity(revealed[safe: i] == true ? 1.0 : 0.0)
                                .animation(
                                    completed[i] ? .spring(response: 0.3, dampingFraction: 0.40)
                                        : .smooth(duration: dayDelaySeconds), value: revealed,
                                )
                                .sensoryFeedback(
                                    .impact(
                                        flexibility: .rigid,
                                        intensity: intensity,
                                    ),
                                    trigger: revealed[safe: i] == true && completed[i],
                                )
                                .zIndex(1)

                            // I have hidden this for now
                            /*
                             // Particle burst when a completed day is revealed
                             if completed[i] && (revealed[safe: i] == true) {
                                 ParticleBurst(count: 10, baseColor: .orange, duration: 0.45)
                                     .transition(.opacity)
                                     .zIndex(2)
                             }
                              */
                        }
                    }
                    .frame(minWidth: 22)
                    .padding([.leading, .trailing], 5)
                    .padding([.top, .bottom], 5)
                    .overlay(
                        todaysDateInt == i + 1 ?
                            TodayOutline(draw: drawTodayStroke) : nil,
                    )
                }
            }

            Spacer()
            // Now show the number with the icon
            streakBadge()
                .padding(.trailing, 5)
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + startAnimationDelaySeconds) {
                // Initialize revealed array to false for each day
                if revealed.count != completed.count {
                    revealed = Array(repeating: false, count: completed.count)
                }
                // Stagger the pop-in
                for i in completed.indices {
                    let delay = Double(i) * dayDelaySeconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        if i < revealed.count { revealed[i] = true }
                    }
                }
                // Begin drawing today's outline shortly after reveals start
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    drawTodayStroke = 1.0
                }
                // After all day reveals, show badge then flip digits
                let lastDelay = Double(max(0, completed.count - 1)) * 0.15
                DispatchQueue.main.asyncAfter(deadline: .now() + lastDelay) {
                    showBadge = true
                    // Sequentially reveal each numeric digit with a small cadence
                    let chars = Array(streakCount.formatted(.number.grouping(.automatic)))
                    let totalDigits = chars.count(where: { Int(String($0)) != nil })
                    revealedDigits = 0
                    for step in 0 ..< totalDigits {
                        let delay = Double(step) * 0.08
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            revealedDigits = step + 1
                        }
                    }
                }
            }
        }
    }

    /// Animated streak badge: flame appears, then digits flip in sequence
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
            // now go through each digit
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
                            perspective: 0.6,
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

private struct TodayOutline: View {
    var draw: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .trim(from: 0, to: max(0, min(1, draw)))
            .stroke(.tertiary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .animation(.easeInOut(duration: 1.5), value: draw)
    }
}

/// Safe index helper to avoid out-of-bounds during animation initialization
private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Date {
    func dayNumberOfWeek() -> Int? {
        Calendar.current.dateComponents([.weekday], from: self).weekday
    }
}

#Preview {
    StreakWidget(completed: [true, false, true, false, true, false, true], streakCount: 1234)
        .environment(\.font, .app())
}
