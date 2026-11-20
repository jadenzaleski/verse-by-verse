//
//  PassageScoreChartData.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/19/26.
//

import Foundation

/// How far back the passage History chart looks.
nonisolated enum ChartDuration: String, CaseIterable, Identifiable {
    case week = "1W"
    case month = "1M"
    case sixMonths = "6M"
    case year = "1Y"
    case all = "All"

    var id: String {
        rawValue
    }
}

/// Everything the passage History chart draws and reacts to, as plain values:
/// the visible window, the practice dots, the score curve, the line's colour
/// span and what a drag selects. The view only renders it.
///
/// `ID` identifies a practice session, so a dot can be mapped back to the
/// session it stands for without this type knowing about SwiftData.
nonisolated struct PassageScoreChartData<ID: Hashable> {
    /// A completed practice session, reduced to what placing its dot needs.
    struct SessionInput {
        var id: ID
        var startDate: Date
        var endDate: Date?

        /// When the practice happened: its end, or its start if it never recorded one.
        var date: Date {
            endDate ?? startDate
        }
    }

    /// One practice dot, placed on the curve at the moment of the review.
    struct Marker: Identifiable {
        var id: ID
        var date: Date
        var score: Double
    }

    /// Where the line's red → orange → green gradient starts and ends, as unit-space
    /// y values (the curve's own min…max mapped so 0% is red and 100% is green).
    struct GradientSpan: Equatable {
        var startY: Double
        var endY: Double
    }

    /// What a drag over the chart picks.
    enum Selection {
        /// Snapped to a practice dot.
        case marker(Marker)
        /// A free position on the curve.
        case moment(Date)
    }

    /// Practice dots inside the window, oldest first.
    let markers: [Marker]
    /// The score curve across the window; empty when nothing has been reviewed.
    let curve: [MemoryScorePoint]
    /// Where the curve starts: the window start, but never before the first review.
    /// `nil` when nothing has been reviewed.
    let rangeStart: Date?
    /// `nil` when the curve is empty or flat enough that one colour reads better.
    let gradientSpan: GradientSpan?

    private let now: Date
    private let snapshots: [[ReviewSnapshot]]
    private let scheduler: MemoryScheduler

    /// A drag within 1/80th of the visible span of a dot snaps to it.
    private static var snapDivisor: Double {
        80
    }

    /// - Parameters:
    ///   - sessions: completed sessions, in any order.
    ///   - snapshots: one ascending snapshot list per verse (see ``Verse/reviewSnapshots``).
    init(
        duration: ChartDuration,
        now: Date,
        calendar: Calendar = .current,
        sessions: [SessionInput],
        snapshots: [[ReviewSnapshot]],
        scheduler: MemoryScheduler,
    ) {
        self.now = now
        self.snapshots = snapshots
        self.scheduler = scheduler

        let ordered = sessions.sorted { $0.startDate < $1.startDate }
        let windowStart = Self.windowStart(
            for: duration, now: now, calendar: calendar, earliestSession: ordered.first?.startDate,
        )

        markers = ordered.compactMap { session in
            let date = session.date
            if let windowStart, date < windowStart {
                return nil
            }
            return Marker(
                id: session.id,
                date: date,
                score: MemoryScoreHistory.score(at: date, verses: snapshots, scheduler: scheduler),
            )
        }

        // The curve is anchored by the earliest review, so a line always shows
        // whenever any practice exists, even if the window opens before it.
        guard let firstEver = snapshots.compactMap(\.first?.reviewedAt).min() else {
            curve = []
            rangeStart = nil
            gradientSpan = nil
            return
        }
        let start = max(windowStart ?? firstEver, firstEver)
        rangeStart = start
        curve = MemoryScoreHistory.curve(from: start, to: now, verses: snapshots, scheduler: scheduler)
        gradientSpan = Self.gradientSpan(for: curve.map(\.score))
    }

    /// The start of the visible window; `nil` for All with no sessions.
    static func windowStart(
        for duration: ChartDuration,
        now: Date,
        calendar: Calendar,
        earliestSession: Date?,
    ) -> Date? {
        switch duration {
        case .week: calendar.date(byAdding: .day, value: -7, to: now)
        case .month: calendar.date(byAdding: .month, value: -1, to: now)
        case .sixMonths: calendar.date(byAdding: .month, value: -6, to: now)
        case .year: calendar.date(byAdding: .year, value: -1, to: now)
        case .all: earliestSession
        }
    }

    /// The passage's score at `date`, against every review — correct even when the
    /// latest practice is outside the visible window.
    func score(at date: Date) -> Double {
        MemoryScoreHistory.score(at: date, verses: snapshots, scheduler: scheduler)
    }

    /// What a drag at `date` selects: the nearest dot if it is close enough, else
    /// that moment, clamped to the curve. `nil` when there is no curve.
    func selection(at date: Date) -> Selection? {
        guard let rangeStart else { return nil }
        let clamped = min(max(date, rangeStart), now)
        let threshold = now.timeIntervalSince(rangeStart) / Self.snapDivisor

        let nearest = markers.min {
            abs($0.date.timeIntervalSince(clamped)) < abs($1.date.timeIntervalSince(clamped))
        }
        if let nearest, abs(nearest.date.timeIntervalSince(clamped)) < threshold {
            return .marker(nearest)
        }
        return .moment(clamped)
    }

    private static func gradientSpan(for values: [Double]) -> GradientSpan? {
        guard let low = values.min(), let high = values.max(), high - low >= 0.001 else { return nil }
        return GradientSpan(
            startY: (0.0 - high) / (low - high),
            endY: (1.0 - high) / (low - high),
        )
    }
}
