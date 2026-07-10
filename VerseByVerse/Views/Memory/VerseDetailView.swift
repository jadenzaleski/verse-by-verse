//
//  VerseDetailView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/10/26.
//

import Charts
import SwiftData
import SwiftUI

/// Detail screen for a single tracked verse: live Memory Score, practice
/// entry point, the exact review-by-review retrievability history, the verse
/// text, and where the verse appears.
struct VerseDetailView: View {
    let verse: Verse

    @Environment(BibleStore.self) private var bibleStore

    @State private var showPractice = false

    private let scheduler = FSRSScheduler()

    /// Learning/relearning stability is hours-to-days, so a percentage would
    /// swing wildly within a day — show a state badge instead.
    private var isLearning: Bool {
        verse.state == 1 || verse.state == 3
    }

    private var retentionScore: Double {
        scheduler.retrievability(of: verse.memoryState, at: .now)
    }

    private var sortedReviews: [VerseReview] {
        (verse.reviews ?? []).sorted { $0.reviewedAt < $1.reviewedAt }
    }

    private var dueDateText: String {
        guard let next = verse.nextPractice else {
            return verse.isNew ? "New — start your first practice" : "Ready to practice"
        }
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: next),
        ).day ?? 0
        if days < 0 { return "Overdue by \(-days) day\(-days == 1 ? "" : "s")" }
        if days == 0 { return "Due today" }
        return "Due in \(days) day\(days == 1 ? "" : "s")"
    }

    private var dueDateColor: Color {
        guard let next = verse.nextPractice else {
            return verse.isNew ? .appAccent : .green
        }
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: next),
        ).day ?? 0
        if days < 0 { return .red }
        if days == 0 { return .orange }
        return .secondary
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                memoryScoreCard
                practiceCard
                historyCard
                verseTextCard
                if let passages = verse.passages, !passages.isEmpty {
                    containersCard(passages: passages)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxl)
        }
        .fullScreenCover(isPresented: $showPractice) {
            SessionView(verse: verse)
        }
        .task {
            await bibleStore.fetchSelection(verse.selectionKey)
        }
        .navigationTitle(verse.reference)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Cards

    private var memoryScoreCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Memory Score")
                    .font(.app(.title2))
                Spacer()
                if isLearning {
                    Text("Learning")
                        .font(.app(.caption, weight: .semibold))
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(Color.appAccent.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.appAccent)
                }
            }

            if verse.lastPracticed != nil {
                Text("\(Int(retentionScore * 100))%")
                    .font(.app(.largeTitle, weight: .semibold))
                    .foregroundStyle(retentionScore < 0.6 ? .red : retentionScore < 0.8 ? .orange : .green)
                SegmentedProgressBar(
                    totalSegments: 10,
                    completedSegments: Int(retentionScore * 10),
                    height: 20,
                )
            } else {
                Text("Complete your first practice session to start tracking your memory score.")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: AppSpacing.xl) {
                statItem(label: "Reviews", value: "\(verse.reps)")
                statItem(label: "Missed", value: "\(verse.lapses)")
                if let last = verse.lastPracticed {
                    statItem(label: "Last Practice", value: last.formatted(.relative(presentation: .named)))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private var practiceCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Practice")
                .font(.app(.title2))

            HStack(spacing: AppSpacing.sm) {
                Circle()
                    .fill(dueDateColor)
                    .frame(width: 8, height: 8)
                Text(dueDateText)
                    .font(.app(.subheadline))
                    .foregroundStyle(dueDateColor)
            }

            Button {
                showPractice = true
            } label: {
                Text("Practice This Verse")
                    .font(.app(.body, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppRadius.md)
                    .background(Color.appAccent, in: RoundedRectangle(cornerRadius: AppRadius.md))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("History")
                .font(.app(.title2))
            if sortedReviews.isEmpty {
                Text("No practice history yet.")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            } else {
                VerseMemoryChart(reviews: sortedReviews, scheduler: scheduler)
                    .frame(height: 180)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private var verseTextCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Verse")
                    .font(.app(.title2))
                Spacer()
                Text(verse.translation)
                    .font(.app(.caption, weight: .semibold))
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(Color.secondary.opacity(0.15), in: Capsule())
                    .foregroundStyle(.secondary)
            }
            Text(bibleStore.selections[verse.selectionKey]?.fullText ?? "Loading...")
                .font(.app(.body))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private func containersCard(passages: [Passage]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Appears In")
                .font(.app(.title2))
            ForEach(passages) { passage in
                NavigationLink(destination: PassageDetailView(passage: passage)) {
                    HStack {
                        Text(passage.reference)
                            .font(.app(.subheadline, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.app(.caption))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(value)
                .font(.app(.body, weight: .semibold))
            Text(label)
                .font(.app(.caption))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Sawtooth history chart

/// The verse's exact retrievability curve: decaying between reviews along
/// the engine's own forgetting curve (from each review's stability
/// snapshot), jumping back toward 100% at every review.
private struct VerseMemoryChart: View {
    let reviews: [VerseReview]
    let scheduler: FSRSScheduler

    private struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let retention: Double
        let segment: Int
    }

    private var points: [ChartPoint] {
        var result: [ChartPoint] = []
        let now = Date()

        for (index, review) in reviews.enumerated() {
            let segmentEnd = index + 1 < reviews.count ? reviews[index + 1].reviewedAt : now
            let state = MemoryState(
                stability: review.stabilityAfter,
                difficulty: review.difficultyAfter,
                state: max(review.stateAfter, 1),
                step: 0,
                due: nil,
                lastReviewed: review.reviewedAt,
                reps: 1,
                lapses: 0,
            )

            let duration = segmentEnd.timeIntervalSince(review.reviewedAt)
            guard duration > 0 else {
                result.append(ChartPoint(
                    date: review.reviewedAt,
                    retention: scheduler.retrievability(of: state, at: review.reviewedAt),
                    segment: index,
                ))
                continue
            }
            let sampleCount = 24
            for sample in 0 ... sampleCount {
                let date = review.reviewedAt.addingTimeInterval(duration * Double(sample) / Double(sampleCount))
                result.append(ChartPoint(
                    date: date,
                    retention: scheduler.retrievability(of: state, at: date),
                    segment: index,
                ))
            }
        }
        return result
    }

    private var reviewMarkers: [ChartPoint] {
        reviews.enumerated().map { index, review in
            let state = MemoryState(
                stability: review.stabilityAfter,
                difficulty: review.difficultyAfter,
                state: max(review.stateAfter, 1),
                step: 0,
                due: nil,
                lastReviewed: review.reviewedAt,
                reps: 1,
                lapses: 0,
            )
            return ChartPoint(
                date: review.reviewedAt,
                retention: scheduler.retrievability(of: state, at: review.reviewedAt),
                segment: index,
            )
        }
    }

    var body: some View {
        Chart {
            ForEach(points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Memory", point.retention),
                    series: .value("Segment", point.segment),
                )
                .foregroundStyle(Color.appAccent)
                .interpolationMethod(.monotone)
            }
            ForEach(reviewMarkers) { marker in
                PointMark(
                    x: .value("Date", marker.date),
                    y: .value("Memory", marker.retention),
                )
                .foregroundStyle(Color.appAccent)
                .symbolSize(40)
            }
        }
        .chartYScale(domain: 0 ... 1)
        .chartYAxis {
            AxisMarks(values: [0, 0.5, 1]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let number = value.as(Double.self) {
                        Text("\(Int(number * 100))%")
                            .font(.app(.caption2))
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        VerseDetailView(verse: PreviewData.sampleVerse)
    }
    .modelContainer(PreviewData.container)
    .environment(BibleStore.shared)
    .environment(\.font, .app())
}
