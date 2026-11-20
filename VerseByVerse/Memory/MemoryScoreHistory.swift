//
//  MemoryScoreHistory.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/18/26.
//

import Foundation

/// A value copy of one ``VerseReview``'s FSRS snapshot — everything needed to
/// recompute the Memory Score as it stood at any later date, without touching
/// SwiftData.
nonisolated struct ReviewSnapshot: Equatable {
    var reviewedAt: Date
    /// What you scored in that review (0…1).
    var score: Double
    var stability: Double
    var difficulty: Double
    var state: Int

    /// The FSRS state right after the review, as the ``MemoryScheduler`` seam sees it.
    var memoryState: MemoryState {
        MemoryState(
            stability: stability,
            difficulty: difficulty,
            state: max(state, 1),
            step: 0,
            due: nil,
            lastReviewed: reviewedAt,
            reps: 1,
            lapses: 0,
        )
    }

    /// The Memory Score this review's result has decayed to by `date`. The one place a
    /// stored review becomes a score, so every chart and card computes it identically.
    func memoryScore(using scheduler: MemoryScheduler, at date: Date) -> Double {
        scheduler.memoryScore(of: memoryState, lastResult: score, at: date)
    }
}

nonisolated extension ReviewSnapshot {
    init(_ review: VerseReview) {
        self.init(
            reviewedAt: review.reviewedAt,
            score: review.score,
            stability: review.stabilityAfter,
            difficulty: review.difficultyAfter,
            state: review.stateAfter,
        )
    }
}

extension Verse {
    /// This verse's reviews as value snapshots, oldest first. (`reviews` is an
    /// unordered relationship, so the sort is what makes "newest wins" safe.)
    var reviewSnapshots: [ReviewSnapshot] {
        (reviews ?? []).map { ReviewSnapshot($0) }.sorted { $0.reviewedAt < $1.reviewedAt }
    }
}

/// One sample of a passage's Memory Score over time.
nonisolated struct MemoryScorePoint: Identifiable, Equatable {
    var date: Date
    var score: Double
    var id: Date {
        date
    }
}

/// The passage History chart's score, recomputed from each verse's review
/// snapshots with the same function the Memory Score card uses
/// (``MemoryScheduler/memoryScore(of:lastResult:at:)``), so the two cannot disagree.
nonisolated enum MemoryScoreHistory {
    /// The passage's Memory Score at `date`: the mean, over `verses`, of each verse's
    /// score. A verse with no review on or before `date` counts as 0.
    /// - Parameter verses: one snapshot list per verse, each **ascending by `reviewedAt`**
    ///   (see ``Verse/reviewSnapshots``).
    static func score(at date: Date, verses: [[ReviewSnapshot]], scheduler: MemoryScheduler) -> Double {
        guard !verses.isEmpty else { return 0 }
        var total = 0.0
        for snapshots in verses {
            guard let latest = latest(in: snapshots, onOrBefore: date) else { continue }
            total += latest.memoryScore(using: scheduler, at: date)
        }
        return total / Double(verses.count)
    }

    /// The score curve from `start` to `end`: `sampleCount` evenly spaced samples
    /// plus, for every review instant `r` in `(start, end]`, samples at `r − 1s` and
    /// `r` so each practice shows as a vertical jump. Dates are strictly increasing.
    static func curve(
        from start: Date,
        to end: Date,
        verses: [[ReviewSnapshot]],
        sampleCount: Int = 250,
        scheduler: MemoryScheduler,
    ) -> [MemoryScorePoint] {
        guard end > start else { return [] }
        let count = max(sampleCount, 2)
        let span = end.timeIntervalSince(start)

        var dates = (0 ..< count).map { index in
            index == count - 1 ? end : start.addingTimeInterval(span * Double(index) / Double(count - 1))
        }
        for snapshots in verses {
            for snapshot in snapshots where snapshot.reviewedAt > start && snapshot.reviewedAt <= end {
                dates.append(snapshot.reviewedAt)
                dates.append(snapshot.reviewedAt.addingTimeInterval(-1))
            }
        }
        dates.sort()

        var unique: [Date] = []
        for date in dates where date >= start && date > (unique.last ?? .distantPast) {
            unique.append(date)
        }
        return unique.map { MemoryScorePoint(date: $0, score: score(at: $0, verses: verses, scheduler: scheduler)) }
    }

    /// Binary search for the newest snapshot at or before `date` in an ascending list.
    private static func latest(in snapshots: [ReviewSnapshot], onOrBefore date: Date) -> ReviewSnapshot? {
        var low = 0
        var high = snapshots.count
        while low < high {
            let mid = (low + high) / 2
            if snapshots[mid].reviewedAt <= date {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return low > 0 ? snapshots[low - 1] : nil
    }
}
