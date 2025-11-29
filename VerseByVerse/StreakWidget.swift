//
//  StreakWidget.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/27/25.
//

import SwiftUI

struct StreakWidget: View {
    let completed: [Bool] = [true, true, true, false, true, true, true]
    let dayLetters: [String] = ["S", "M", "T", "W", "T", "F", "S"]
    let streakCount: Int = 1675

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            GeometryReader { geo in
                let circleSize: CGFloat = 20
                let totalWidth = geo.size.width
                let itemWidth = totalWidth / CGFloat(completed.count) // each letter/circle gets same width

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
                            let lineWidth = CGFloat(seg.end - seg.start) * itemWidth + circleSize
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
                                .frame(width: lineWidth, height: circleSize)
                                .offset(x: xOffset)
                        }

                        // Circles on top
                        HStack(spacing: 0) {
                            ForEach(0..<completed.count, id: \.self) { i in
                                Circle()
                                    .strokeBorder(!completed[i] ? .secondary : Color.clear, lineWidth: 2)
//                                    .frame(width: circleSize, height: circleSize)
//                                    .frame(width: itemWidth, alignment: .center)
                            }
                        }
                    }
                    .frame(height: circleSize)
                }
            }
            .frame(height: 50)

            // Streak count
            Label {
                Text("\(streakCount)")
                    .foregroundColor(.orange)
            } icon: {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
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
