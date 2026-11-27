//
//  PassageMemoryScoreChart.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/4/26.
//

import Charts
import SwiftData
import SwiftUI

/// The passage's Memory Score over time. The curve is recomputed from each verse's
/// review snapshots with the same function the Memory Score card uses
/// (``MemoryScoreHistory``), so the two always agree and the line starts at what
/// you actually scored. The numbers come from ``PassageScoreChartData``; this view
/// only draws them.
struct PassageMemoryScoreChart: View {
    let sessions: [PracticeSession]
    let verses: [Verse]

    private typealias ChartData = PassageScoreChartData<PracticeSession.ID>

    private let scheduler = FSRSScheduler()

    /// What the chart data depends on: the picker, the sessions, and the review count
    /// (which changes whenever any verse is practiced, even from another screen).
    private struct RefreshKey: Equatable {
        let duration: ChartDuration
        let sessions: [PracticeSession]
        let reviewCount: Int
    }

    @State private var selectedSession: PracticeSession?
    @State private var selectedDuration: ChartDuration = .week
    @State private var selectedDate: Date?

    /// Built once per refresh, not per body evaluation or drag frame — rebuilding the
    /// review snapshots faults every `VerseReview`.
    @State private var data: ChartData?

    private var activeRetention: Double {
        score(at: selectedDate ?? Date())
    }

    private var completedSessions: [PracticeSession] {
        sessions.filter(\.isCompleted)
    }

    private var reviewCount: Int {
        verses.reduce(0) { $0 + ($1.reviews?.count ?? 0) }
    }

    /// Against every review, so it is right even when the latest practice is outside
    /// the window. Before the first refresh it falls back to a direct computation.
    private func score(at date: Date) -> Double {
        if let data {
            return data.score(at: date)
        }
        return MemoryScoreHistory.score(at: date, verses: verses.map(\.reviewSnapshots), scheduler: scheduler)
    }

    private func refreshData() {
        data = ChartData(
            duration: selectedDuration,
            now: Date(),
            sessions: completedSessions.map {
                ChartData.SessionInput(id: $0.id, startDate: $0.startDate, endDate: $0.endDate)
            },
            snapshots: verses.map(\.reviewSnapshots),
            scheduler: scheduler,
        )
    }

    private var lineGradient: LinearGradient {
        guard let span = data?.gradientSpan else {
            // Flat (or empty): one colour, the score it sits at.
            return LinearGradient(
                colors: [.score(data?.curve.last?.score ?? 0)], startPoint: .bottom, endPoint: .top,
            )
        }
        // Hard stops at the shared score bands, so the line's colour at any height is `Color.score`
        // of that height — the same as the readout above it.
        return LinearGradient(
            stops: [
                .init(color: .red, location: 0),
                .init(color: .red, location: ScoreBand.orange),
                .init(color: .orange, location: ScoreBand.orange),
                .init(color: .orange, location: ScoreBand.green),
                .init(color: .green, location: ScoreBand.green),
                .init(color: .green, location: 1),
            ],
            startPoint: UnitPoint(x: 0, y: span.startY),
            endPoint: UnitPoint(x: 0, y: span.endY),
        )
    }

    private func select(at date: Date) {
        switch data?.selection(at: date) {
        case let .marker(marker):
            selectedDate = marker.date
            selectedSession = completedSessions.first { $0.id == marker.id }
        case let .moment(moment):
            selectedDate = moment
            selectedSession = nil
        case nil:
            break
        }
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
                        .foregroundStyle(Color.score(activeRetention))

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
                ForEach(data?.curve ?? []) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Memory Score", point.score),
                    )
                    .foregroundStyle(lineGradient)
                }

                // Practice Sessions (Points, on the line)
                ForEach(data?.markers ?? []) { marker in
                    PointMark(
                        x: .value("Date", marker.date),
                        y: .value("Memory Score", marker.score),
                    )
                    .symbolSize(selectedSession?.id == marker.id ? 120 : 60)
                    .foregroundStyle(Color.appAccent)
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
                                    if let date: Date = proxy.value(atX: value.location.x) {
                                        select(at: date)
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
            .padding(.top, AppSpacing.md)
        }
        .task(id: RefreshKey(duration: selectedDuration, sessions: sessions, reviewCount: reviewCount)) {
            refreshData()
        }
    }
}

#Preview {
    let container = AppModelContainer.make(inMemory: true)
    let context = container.mainContext
    let scheduler = FSRSScheduler()
    let calendar = Calendar.current
    let now = Date()

    let verse = try? Verse.findOrCreate(
        translation: "ESV", book: "Psalms", chapter: 23, number: 1, in: context,
    )
    var sessions: [PracticeSession] = []
    let daysAgoAndScores: [(Int, Double)] = [(-12, 0.76), (-9, 0.88), (-4, 0.70), (-1, 0.95)]
    for (daysAgo, score) in daysAgoAndScores {
        let day = calendar.date(byAdding: .day, value: daysAgo, to: now) ?? now
        let session = PracticeSession(startDate: day.addingTimeInterval(-300))
        session.endDate = day
        session.score = score
        session.rating = MemoryScoring.rating(forScore: score)
        context.insert(session)
        sessions.append(session)

        guard let verse else { continue }
        let outcome = scheduler.processReview(state: verse.memoryState, score: score, at: day)
        let review = VerseReview(reviewedAt: day)
        review.score = score
        review.rating = outcome.rating
        review.stabilityAfter = outcome.state.stability ?? 0
        review.difficultyAfter = outcome.state.difficulty ?? 0
        review.stateAfter = outcome.state.state
        review.verse = verse
        review.session = session
        verse.memoryState = outcome.state
    }

    return PassageMemoryScoreChart(sessions: sessions, verses: verse.map { [$0] } ?? [])
        .environment(\.font, .app())
        .padding()
        .modelContainer(container)
}
