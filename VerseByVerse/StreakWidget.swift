//
//  StreakWidget.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/27/25.
//

import SwiftUI

struct StreakWidget: View {
    @State private var segmentProgress: [CGFloat] = []
    @State private var showLabel = false
    @State private var showFlame = false
    @State private var showNumber = false
    let completed: [Bool] = [true, true, true, false, true, true, true]
    let dayLetters: [String] = ["S", "M", "T", "W", "T", "F", "S"]
    let streakCount: Int = 1675

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            GeometryReader { geo in
                let pillHeight: CGFloat = 20
                let circleDiameter: CGFloat = 8
                let totalWidth = geo.size.width
                let itemWidth = totalWidth / CGFloat(completed.count)

                let segments = computeSegments(completed: completed)

                VStack(spacing: 6) {
                    // Letters
                    HStack(spacing: 0) {
                        ForEach(0..<dayLetters.count, id: \.self) { i in
                            Text(dayLetters[i])
                                .font(.app(.footnote, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: itemWidth, alignment: .center)
                        }
                    }

                    // Pills + circles
                    ZStack(alignment: .leading) {
                        // Draw streak pills
                        ForEach(segments.indices, id: \.self) { i in
                            let seg = segments[i]
                            let lineWidth = CGFloat(seg.end - seg.start) * itemWidth + pillHeight
                            let startCenter = itemWidth * CGFloat(seg.start + 1) + itemWidth / 2
                            let xOffset = startCenter - lineWidth / 2

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color("CustomPurple"), Color("CustomGreen")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: lineWidth * (i < segmentProgress.count ? segmentProgress[i] : 0), height: pillHeight, alignment: .leading)
                                .opacity({
                                    if i == 0 { return 1 }
                                    guard i - 1 < segmentProgress.count else { return 0 }
                                    return segmentProgress[i - 1] >= 1 ? 1 : 0
                                }())
                                .offset(x: xOffset)
                        }
                        .zIndex(2)

                        // Circles
                        HStack(spacing: 0) {
                            ForEach(0..<completed.count, id: \.self) { i in
                                Circle()
                                    .fill(.secondary)
                                    .frame(width: circleDiameter, height: circleDiameter)
                                    .frame(width: itemWidth, alignment: .center)
                            }
                        }
                    }
                    .onAppear {
                        if segmentProgress.count != segments.count {
                            segmentProgress = Array(repeating: 0, count: segments.count)
                        }

                        for i in segments.indices {
                            let delay = Double(i) * 0.4
                            withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                                if i < segmentProgress.count { segmentProgress[i] = 1 }
                            }
                        }

                        let totalDelay = Double(segments.count) * 0.4

                        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                            // Flame bounce-in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                                showFlame = true
                            }

                            // Number comes in shortly after flame
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.65).delay(0.12)) {
                                showNumber = true
                            }
                        }
                    }
                    .frame(height: max(pillHeight, circleDiameter))
                }
            }
            .frame(height: 50)

            // Streak count
            Label {
                Text("\(streakCount)")
                    .foregroundColor(.orange)
                    .opacity(showNumber ? 1 : 0)
                    .scaleEffect(showNumber ? 1 : 0.4)
            } icon: {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
//                    .opacity(showFlame ? 1 : 0)
//                    .scaleEffect(showFlame ? 1 : 0.2)
                    .symbolEffect(.drawOn.byLayer, options: .nonRepeating, isActive: !showFlame)
            }
            .font(.app(.title2, weight: .semibold))
        }
        .frame(height: 70)
        .padding()
    }
}

struct StreakSegment {
    let start: Int
    let end: Int
}

func computeSegments(completed: [Bool]) -> [StreakSegment] {
    var segments: [StreakSegment] = []
    var startIndex: Int? = nil

    for i in 0..<completed.count {
        if completed[i] {
            if startIndex == nil { startIndex = i }
        }

        if let s = startIndex, (!completed[i] || i == completed.count - 1) {
            let endIndex = completed[i] ? i : i - 1
            segments.append(StreakSegment(start: s, end: endIndex))
            startIndex = nil
        }
    }

    return segments
}

#Preview {
    StreakWidget()
        .environment(\.font, .app())
}
