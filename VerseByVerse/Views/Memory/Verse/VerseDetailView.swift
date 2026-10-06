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

    private let scheduler = FSRSScheduler()
    private let log = AppLog.category("VerseDetailView")

    private var retentionScore: Double {
        scheduler.retrievability(of: verse.memoryState, at: .now)
    }

    private var sortedReviews: [VerseReview] {
        (verse.reviews ?? []).sorted { $0.reviewedAt < $1.reviewedAt }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                MemoryScoreCard(lastPracticed: verse.lastPracticed,
                                totalReps: verse.reps,
                                retentionScore: retentionScore)
                PracticeCard(showPractice: $showPractice, nextPracticeDate: verse.nextPractice, isNew: verse.isNew)
                historyCard
                LongTextCard(
                    title: "Verse",
                    translation: bibleStore.translationInfo(forAbbreviation: verse.translation),
                    text: bibleStore.displayText(for: verse.selectionKey, placeholder: "Loading..."),
                )

                appearsInCard()
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .confirmationDialog(
                    "Delete \(verse.reference)?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible,
                ) {
                    Button(deleteButtonLabel, role: .destructive) {
                        deleteVerse()
                    }
                } message: {
                    Text(deleteMessage)
                }
                .accessibilityLabel("Delete Verse")
            }
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
                                Image(systemName: "chevron.right")
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
                                Image(systemName: "chevron.right")
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

    private var owningPassages: [Passage] {
        verse.passages ?? []
    }

    private var owningSets: [StudySet] {
        verse.studySets ?? []
    }

    private var deleteButtonLabel: String {
        owningPassages.isEmpty ? "Delete" : "Delete Passage & Verses"
    }

    private var deleteMessage: String {
        let message = if owningPassages.isEmpty {
            "This verse will be removed from any sets and deleted."
        } else if owningPassages.count == 1 {
            "This will delete \(owningPassages[0].reference) and all its verses."
        } else {
            "This will delete \(owningPassages.count) passages and all their verses."
        }

        return message + " This can't be undone."
    }

    private func deleteVerse() {
        for set in owningSets {
            set.verses?.removeAll { $0 === verse }
            set.modifiedAt = .now
        }
        for passage in owningPassages {
            modelContext.delete(passage)
        }
        verse.addedDirectly = false
        do {
            try Verse.sweepOrphans(in: modelContext)
            try modelContext.save()
            dismiss()
        } catch {
            log.error("Failed to delete verse: \(error)")
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
