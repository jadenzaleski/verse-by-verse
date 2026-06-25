//
//  WeeklySessionsChart.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/10/26.
//

import Charts
import SwiftUI

/// A continuously-scrolling daily practice-sessions chart, modeled on the
/// Health app's Resting Heart Rate graph: a 7-day window that snaps to days,
/// with the visible window's average shown above. Tapping a day reveals a rule
/// line and that day's detail in the header.
struct WeeklySessionsChart: View {
    let sessions: [PracticeSession]

    /// Leading (earliest) edge of the visible 7-day window. Drives the average.
    @State private var scrollPositionX: Date
    /// The day the user tapped, if any.
    @State private var rawSelectedDate: Date?

    private let calendar = Calendar.current
    private let visibleDayCount = 7

    init(sessions: [PracticeSession]) {
        self.sessions = sessions
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Default to the most recent 7-day window.
        _scrollPositionX = State(initialValue: cal.date(byAdding: .day, value: -6, to: today)!)
    }

    private struct DayCount: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }

    /// Completed sessions grouped by calendar day.
    private var sessionsByDay: [Date: Int] {
        var counts: [Date: Int] = [:]
        for session in sessions where session.isCompleted {
            let day = calendar.startOfDay(for: session.startDate)
            counts[day, default: 0] += 1
        }
        return counts
    }

    /// One point per day from the earliest session (or a week ago, whichever is
    /// earlier) through today, with zero-filled gaps so the line is continuous.
    private var dailyCounts: [DayCount] {
        let today = calendar.startOfDay(for: Date())
        let earliest = sessionsByDay.keys.min() ?? today
        let weekAgo = calendar.date(byAdding: .day, value: -(visibleDayCount - 1), to: today)!
        var day = min(earliest, weekAgo)
        var result: [DayCount] = []
        while day <= today {
            result.append(DayCount(date: day, count: sessionsByDay[day] ?? 0))
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        return result
    }

    /// Consistent Y domain so busy windows visibly stand taller. The `+ 1`
    /// gives the topmost dot headroom so it isn't clipped at the edge.
    private var yDomain: ClosedRange<Double> {
        0 ... (Double(max(sessionsByDay.values.max() ?? 0, 3)) + 1)
    }

    private var windowStart: Date {
        calendar.startOfDay(for: scrollPositionX)
    }

    private var windowEnd: Date {
        calendar.date(byAdding: .day, value: visibleDayCount - 1, to: windowStart)!
    }

    private var visibleDays: [DayCount] {
        dailyCounts.filter { $0.date >= windowStart && $0.date <= windowEnd }
    }

    private var visibleAverage: Double {
        let days = visibleDays
        guard !days.isEmpty else { return 0 }
        return Double(days.reduce(0) { $0 + $1.count }) / Double(days.count)
    }

    private var selectedDay: DayCount? {
        guard let rawSelectedDate else { return nil }
        let day = calendar.startOfDay(for: rawSelectedDate)
        return dailyCounts.first { calendar.isDate($0.date, inSameDayAs: day) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice Sessions")
                .font(.app(.title3))
                .padding(.horizontal)

            header
                .padding(.horizontal)

            chart
                .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        if let selectedDay {
            statHeader(
                caption: selectedDay.date.formatted(.dateTime.weekday(.wide)).uppercased(),
                value: "\(selectedDay.count)",
                unit: selectedDay.count == 1 ? "session" : "sessions",
                subtitle: selectedDay.date.formatted(.dateTime.month(.wide).day().year()),
            )
        } else {
            statHeader(
                caption: "AVERAGE",
                value: averageString,
                unit: "sessions/day",
                subtitle: "\(windowStart.formatted(.dateTime.month(.abbreviated).day())) – "
                    + windowEnd.formatted(.dateTime.month(.abbreviated).day()),
            )
        }
    }

    private func statHeader(caption: String, value: String, unit: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(caption)
                .font(.app(.caption, weight: .semibold))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.app(.largeTitle, weight: .bold))
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            }
            Text(subtitle)
                .font(.app(.caption))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeOut(duration: 0.15), value: value)
    }

    private var averageString: String {
        let avg = visibleAverage
        return avg == avg.rounded() ? String(Int(avg)) : String(format: "%.1f", avg)
    }

    // MARK: - Chart

    private var chart: some View {
        Chart(dailyCounts) { day in
            LineMark(
                x: .value("Day", day.date, unit: .day),
                y: .value("Sessions", day.count),
            )
            .interpolationMethod(.linear)
            .foregroundStyle(Color.accentColor)

            PointMark(
                x: .value("Day", day.date, unit: .day),
                y: .value("Sessions", day.count),
            )
            .foregroundStyle(Color.accentColor)
            .symbol {
                // Opaque center masks the line passing behind the hollow dot.
                Circle()
                    .fill(Color(.systemBackground))
                    .overlay { Circle().stroke(Color.accentColor, lineWidth: 2) }
                    .frame(width: 9, height: 9)
            }

            if let selectedDay, calendar.isDate(selectedDay.date, inSameDayAs: day.date) {
                RuleMark(x: .value("Day", selectedDay.date, unit: .day))
                    .foregroundStyle(Color.secondary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                PointMark(
                    x: .value("Day", selectedDay.date, unit: .day),
                    y: .value("Sessions", selectedDay.count),
                )
                .foregroundStyle(Color.accentColor)
                .symbolSize(90)
            }
        }
        .chartYScale(domain: yDomain)
        .chartXVisibleDomain(length: 86400 * visibleDayCount)
        .chartScrollableAxes(.horizontal)
        .chartScrollPosition(x: $scrollPositionX)
        .chartScrollTargetBehavior(.valueAligned(matching: DateComponents(hour: 0)))
        .chartXSelection(value: $rawSelectedDate)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) {
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .frame(height: 200)
    }
}

#Preview {
    let now = Date()
    let cal = Calendar.current
    let sessions: [PracticeSession] = (0 ..< 80).map { i in
        let day = cal.date(byAdding: .day, value: -Int.random(in: 0 ..< 60), to: now)!
        return PracticeSession(
            id: i,
            userId: "u1",
            passageId: 1,
            startDate: day,
            endDate: day.addingTimeInterval(300),
            score: 0.8,
            rating: 3,
            scheduledDays: 5,
            elapsedDays: 4,
            state: 1,
        )
    }

    WeeklySessionsChart(sessions: sessions)
        .environment(\.font, .app())
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        .padding()
}
