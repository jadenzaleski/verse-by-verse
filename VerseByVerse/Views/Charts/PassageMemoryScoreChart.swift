//
//  PassageMemoryScoreChart.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/4/26.
//

import Charts
import SwiftUI

struct MemoryPoint: Identifiable {
    let id = UUID()
    let date: Date
    let retention: Double
}

enum ChartDuration: String, CaseIterable, Identifiable {
    case week = "1W"
    case month = "1M"
    case sixMonths = "6M"
    case year = "1Y"
    case all = "All"

    var id: String {
        rawValue
    }
}

struct PassageMemoryScoreChart: View {
    let sessions: [PracticeSession]

    @State private var selectedSession: PracticeSession?
    @State private var selectedDuration: ChartDuration = .week
    @State private var selectedDate: Date?

    // Memoized Data
    @State private var memoizedFilteredSessions: [PracticeSession] = []
    @State private var memoizedCurve: [MemoryPoint] = []
    @State private var memoizedGradient: LinearGradient = .init(colors: [.green], startPoint: .bottom, endPoint: .top)

    private var activeRetention: Double {
        if let selectedDate {
            return retention(at: selectedDate)
        }
        return currentRetention
    }

    private var currentRetention: Double {
        retention(at: Date())
    }

    private func retention(at date: Date) -> Double {
        // Use pre-sorted memoized data if available, otherwise fallback
        let dateSortedSessions = sessions.sorted(by: { $0.startDate < $1.startDate })
        let data = memoizedFilteredSessions.isEmpty ? dateSortedSessions : memoizedFilteredSessions

        guard let lastSession = data.last(where: { $0.startDate <= date }) else {
            return data.first?.score ?? 1.0
        }
        let daysSince = date.timeIntervalSince(lastSession.startDate) / 86400
        let stability = Double(lastSession.scheduledDays ?? 1)
        return pow(0.9, daysSince / max(1.0, stability))
    }

    private func refreshMemoizedData() {
        let now = Date()
        let calendar = Calendar.current

        // 1. Filter and Sort Sessions
        let filtered = sessions.filter { session in
            guard session.isCompleted else { return false }

            switch selectedDuration {
            case .week:
                return session.startDate > calendar.date(byAdding: .day, value: -7, to: now)!
            case .month:
                return session.startDate > calendar.date(byAdding: .month, value: -1, to: now)!
            case .sixMonths:
                return session.startDate > calendar.date(byAdding: .month, value: -6, to: now)!
            case .year:
                return session.startDate > calendar.date(byAdding: .year, value: -1, to: now)!
            case .all:
                return true
            }
        }.sorted(by: { $0.startDate < $1.startDate })

        memoizedFilteredSessions = filtered

        // 2. Generate Curve with Adaptive Resolution
        guard let firstSession = filtered.first else {
            memoizedCurve = []
            return
        }

        var points: [MemoryPoint] = []
        let totalInterval = now.timeIntervalSince(firstSession.startDate)

        // Aim for ~250 points across the visible range for smooth performance
        let stepInterval = max(3600, totalInterval / 250)

        for i in 0 ..< filtered.count {
            let session = filtered[i]
            let endDate = (i + 1 < filtered.count) ? filtered[i + 1].startDate : now

            let segmentInterval = endDate.timeIntervalSince(session.startDate)
            let stepCount = Int(segmentInterval / stepInterval)

            for step in 0 ... max(1, stepCount) {
                let pointDate = session.startDate.addingTimeInterval(TimeInterval(step) * stepInterval)
                if pointDate > endDate { break }

                let daysSince = pointDate.timeIntervalSince(session.startDate) / 86400
                let stability = Double(session.scheduledDays ?? 1)
                let retention = pow(0.9, daysSince / max(1.0, stability))
                points.append(MemoryPoint(date: pointDate, retention: retention))
            }
        }
        memoizedCurve = points

        // 3. Calculate Gradient
        let values = points.map(\.retention)
        let minR = values.min() ?? 0
        let maxR = values.max() ?? 1
        let range = maxR - minR

        if range < 0.001 {
            memoizedGradient = LinearGradient(colors: [.green], startPoint: .bottom, endPoint: .top)
        } else {
            let startY = (0.0 - maxR) / (minR - maxR)
            let endY = (1.0 - maxR) / (minR - maxR)

            memoizedGradient = LinearGradient(
                stops: [
                    .init(color: .red, location: 0),
                    .init(color: .orange, location: 0.5),
                    .init(color: .green, location: 1),
                ],
                startPoint: UnitPoint(x: 0, y: startY),
                endPoint: UnitPoint(x: 0, y: endY),
            )
        }
    }

    private func color(for score: Double) -> Color {
        switch score {
        case 0 ..< 0.6: .red
        case 0.6 ..< 0.8: .orange
        default: .green
        }
    }

    private func nearestSession(to date: Date) -> PracticeSession? {
        memoizedFilteredSessions.min(by: {
            abs($0.startDate.timeIntervalSince(date)) <
                abs($1.startDate.timeIntervalSince(date))
        })
    }

    var body: some View {
        VStack {
            Picker("Duration", selection: $selectedDuration) {
                ForEach(ChartDuration.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(Int(activeRetention * 100))%")
                        .font(.app(.largeTitle, weight: .semibold))
                        .contentTransition(.numericText())
                        .foregroundStyle(activeRetention < 0.6 ? .orange : .green)

                    Text(selectedDate?.formatted(.dateTime.month().day().hour().minute()) ?? "CURRENT MEMORY SCORE")
                        .font(.app(.caption))
                        .foregroundColor(.secondary)
                }

                Spacer()
                if let session = selectedSession {
                    VStack(alignment: .trailing) {
                        Text("\(Int((session.score ?? 0.0) * 100))%")
                            .font(.app(.largeTitle, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("PRACTICE SCORE")
                            .font(.app(.caption))
                            .foregroundColor(.secondary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .animation(.spring(), value: selectedSession)
            .animation(.easeOut(duration: 0.1), value: activeRetention)

            Chart {
                // Retention Curve (Line)
                ForEach(memoizedCurve) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Retention", point.retention),
                    )
                    .foregroundStyle(memoizedGradient)
                }

                // Practice Sessions (Points)
                ForEach(memoizedFilteredSessions) { session in
                    PointMark(
                        x: .value("Date", session.startDate),
                        y: .value("Score", session.score ?? 0.0),
                    )
                    .symbolSize(selectedSession?.id == session.id ? 120 : 60)
                    .foregroundStyle(.accent)
                }

                if let selectedDate {
                    RuleMark(x: .value("Date", selectedDate))
                        .foregroundStyle(.secondary)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
            }
            .chartYScale(domain: 0 ... 1)
            .chartXAxis {
                AxisMarks()
            }
            .chartYAxis {
                AxisMarks(
                    values: [0, 0.5, 1],
                ) {
                    AxisValueLabel(format: Decimal.FormatStyle.Percent.percent)
                }

                AxisMarks(
                    values: [0, 0.25, 0.5, 0.75, 1.0],
                ) {
                    AxisGridLine()
                }
            }
            .chartOverlay { proxy in
                GeometryReader { _ in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let location = value.location
                                    if let date: Date = proxy.value(atX: location.x) {
                                        let now = Date()
                                        guard let firstDate = memoizedFilteredSessions.first?.startDate else { return }
                                        // Clamp date between first session and now
                                        let clampedDate = min(max(date, firstDate), now)

                                        // Slight snap logic
                                        let nearest = nearestSession(to: clampedDate)
                                        let timeRange = now.timeIntervalSince(firstDate)
                                        let threshold = timeRange / 80

                                        if let nearest, abs(nearest.startDate.timeIntervalSince(clampedDate)) < threshold {
                                            selectedDate = nearest.startDate
                                            selectedSession = nearest
                                        } else {
                                            selectedDate = clampedDate
                                            selectedSession = nil
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    selectedSession = nil
                                    selectedDate = nil
                                },
                        )
                }
            }
            .frame(height: 220)
            .padding(.top, 10)
        }
        .task(id: selectedDuration) {
            refreshMemoizedData()
        }
        .task(id: sessions) {
            refreshMemoizedData()
        }
    }
}

#Preview {
    let now = Date()
    let calendar = Calendar.current

    let sessions: [PracticeSession] = [
        PracticeSession(id: 1, userId: "u1", passageId: 1,
                        startDate: calendar.date(byAdding: .day, value: -12, to: now)!,
                        endDate: calendar.date(byAdding: .day, value: -12, to: now)!.addingTimeInterval(300),
                        score: 0.85, rating: 3, scheduledDays: 2, elapsedDays: 1, state: 1),
        PracticeSession(id: 2, userId: "u1", passageId: 1,
                        startDate: calendar.date(byAdding: .day, value: -9, to: now)!,
                        endDate: calendar.date(byAdding: .day, value: -9, to: now)!.addingTimeInterval(300),
                        score: 0.92, rating: 4, scheduledDays: 5, elapsedDays: 3, state: 1),
        PracticeSession(id: 3, userId: "u1", passageId: 1,
                        startDate: calendar.date(byAdding: .day, value: -4, to: now)!,
                        endDate: calendar.date(byAdding: .day, value: -4, to: now)!.addingTimeInterval(300),
                        score: 0.70, rating: 2, scheduledDays: 4, elapsedDays: 5, state: 1),
        PracticeSession(id: 4, userId: "u1", passageId: 1,
                        startDate: calendar.date(byAdding: .day, value: -1, to: now)!,
                        endDate: calendar.date(byAdding: .day, value: -1, to: now)!.addingTimeInterval(300),
                        score: 0.95, rating: 5, scheduledDays: 10, elapsedDays: 3, state: 1),
    ]

    PassageMemoryScoreChart(sessions: sessions)
        .environment(\.font, .app())
        .padding()
}
