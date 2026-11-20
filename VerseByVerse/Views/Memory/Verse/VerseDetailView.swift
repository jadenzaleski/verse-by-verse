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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showPractice = false
    @State private var showDeleteConfirmation = false
    @State private var isStartButtonVisible = true

    private let scheduler = FSRSScheduler()
    private let log = AppLog.category("VerseDetailView")

    private var retentionScore: Double {
        verse.memoryScore(using: scheduler)
    }

    private var sortedReviews: [VerseReview] {
        (verse.reviews ?? []).sorted { $0.reviewedAt < $1.reviewedAt }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                MemoryScoreCard(
                    lastPracticed: verse.lastPracticed,
                    totalReps: verse.reps,
                    retentionScore: retentionScore,
                    lastResult: verse.lastResult,
                    nextPracticeDate: verse.nextPractice,
                    isNew: verse.isNew,
                )
                PracticeStartButton(isVisible: $isStartButtonVisible) { showPractice = true }

                SelectionTextCard(
                    title: "Verse",
                    translation: verse.translation,
                    key: verse.selectionKey,
                    verses: [verse],
                )
                historyCard

                appearsInCard()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxl)
        }
        .fullScreenCover(isPresented: $showPractice) {
            SessionView(verse: verse)
        }
        .navigationTitle(verse.reference)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            PracticeToolbar(
                deleteTitle: "Delete Verse",
                showsPractice: !isStartButtonVisible,
                onPractice: { showPractice = true },
                onDelete: { showDeleteConfirmation = true },
            )
        }
        .confirmationDialog(
            "Delete \(verse.reference)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible,
        ) {
            Button(verse.deleteConfirmationLabel, role: .destructive) {
                deleteVerse()
            }
        } message: {
            Text(verse.deleteConfirmationMessage)
        }
    }

    // MARK: - Cards

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

    @ViewBuilder
    private func appearsInCard() -> some View {
        let passages = verse.passages ?? []
        let sets = verse.studySets ?? []

        if !passages.isEmpty || !sets.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Appears In")
                    .font(.app(.title2))

                if !passages.isEmpty {
                    Text("Passage" + (passages.count > 1 ? "s" : ""))
                        .font(.app(.headline))
                    ForEach(passages) { passage in
                        NavigationLink(destination: PassageDetailView(passage: passage)) {
                            HStack {
                                Text(passage.reference)
                                    .font(.app(.subheadline, weight: .semibold))
                                Spacer()
                                Image("lucide.chevron.right")
                                    .font(.app(.caption))
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if passages.last != passage {
                            Divider()
                        }
                    }
                }

                if !sets.isEmpty {
                    Text("Set" + (sets.count > 1 ? "s" : ""))
                        .font(.app(.headline))
                    ForEach(sets) { set in
                        NavigationLink(destination: SetDetailView(set: set)) {
                            HStack {
                                Text(set.name)
                                    .font(.app(.subheadline, weight: .semibold))
                                Spacer()
                                Image("lucide.chevron.right")
                                    .font(.app(.caption))
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if sets.last != set {
                            Divider()
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        }
    }

    // MARK: - Delete

    private func deleteVerse() {
        do {
            try verse.deleteFromLibrary(in: modelContext)
            dismiss()
        } catch {
            log.error("Failed to delete verse: \(error)")
        }
    }
}

// MARK: - Sawtooth history chart

/// The verse's Memory Score curve: each review's result decaying along the
/// engine's own forgetting curve (from that review's stability snapshot),
/// jumping to the new result at every review — the same number the card shows.
private struct VerseMemoryChart: View {
    let reviews: [VerseReview]
    let scheduler: FSRSScheduler

    private struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let retention: Double
        let segment: Int
    }

    private var snapshots: [ReviewSnapshot] {
        reviews.map { ReviewSnapshot($0) }
    }

    private var points: [ChartPoint] {
        var result: [ChartPoint] = []
        let now = Date()
        let snapshots = snapshots

        for (index, snapshot) in snapshots.enumerated() {
            let segmentEnd = index + 1 < snapshots.count ? snapshots[index + 1].reviewedAt : now
            let duration = segmentEnd.timeIntervalSince(snapshot.reviewedAt)
            guard duration > 0 else {
                result.append(ChartPoint(
                    date: snapshot.reviewedAt,
                    retention: snapshot.memoryScore(using: scheduler, at: snapshot.reviewedAt),
                    segment: index,
                ))
                continue
            }
            let sampleCount = 24
            for sample in 0 ... sampleCount {
                let date = snapshot.reviewedAt.addingTimeInterval(duration * Double(sample) / Double(sampleCount))
                result.append(ChartPoint(
                    date: date,
                    retention: snapshot.memoryScore(using: scheduler, at: date),
                    segment: index,
                ))
            }
        }
        return result
    }

    private var reviewMarkers: [ChartPoint] {
        snapshots.enumerated().map { index, snapshot in
            ChartPoint(
                date: snapshot.reviewedAt,
                retention: snapshot.memoryScore(using: scheduler, at: snapshot.reviewedAt),
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
    .environment(PreviewData.bibleStore)
    .environment(\.font, .app())
}
