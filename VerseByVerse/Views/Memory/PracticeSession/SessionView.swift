//
//  SessionView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/8/26.
//

import SwiftData
import SwiftUI

private enum SessionPhase: Equatable {
    case loading
    case activity
    case done(nextReview: Date?, correct: Int, total: Int)
    case failed(String)
}

struct SessionView: View {
    let passage: Passage

    @Environment(BibleStore.self) private var bibleStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var phase: SessionPhase = .loading
    @State private var showAbandonConfirmation = false
    @State private var sessionStartDate = Date()
    @State private var steps: [ActivityStep] = []
    @State private var stepIndex = 0
    @State private var stepStartDate = Date()
    @State private var totalCorrect = 0
    @State private var totalPossible = 0
    @State private var collectedActivities: [ActivityRecord] = []

    private let scheduler = FSRSScheduler()
    private let log = AppLog.category("SessionView")

    private var verseText: String {
        bibleStore.selections[passage.selectionKey]?.fullText ?? ""
    }

    private var words: [String] {
        verseText.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    }

    private var canDismiss: Bool {
        phase == .loading || phase == .activity
    }

    var body: some View {
        NavigationStack {
            if phase == .activity {
                SegmentedProgressBar(
                    totalSegments: steps.count,
                    completedSegments: stepIndex,
                    fill: .solid(.appAccent),
                    highlightCurrent: true,
                )
                .padding(.horizontal)
            }
            Group {
                switch phase {
                case .loading:
                    loadingView
                case .activity:
                    activityContent
                case let .done(nextReview, correct, total):
                    doneView(nextReview: nextReview, correct: correct, total: total)
                case let .failed(msg):
                    failedView(message: msg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if canDismiss {
                        Button {
                            if phase == .activity {
                                showAbandonConfirmation = true
                            } else {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(passage.reference)
                        .font(.app(.headline))
                }
            }
        }
        .task {
            await startSession()
        }
        .alert("Quit Session?", isPresented: $showAbandonConfirmation) {
            Button("Quit", role: .destructive) { dismiss() }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Your progress won't be saved.")
        }
    }

    // MARK: - Activity routing

    @ViewBuilder
    private var activityContent: some View {
        if stepIndex < steps.count {
            switch steps[stepIndex] {
            case let .everyOtherWord(phase):
                ActivityView(
                    activityName: "Every Other Word",
                    passage: passage,
                    verseText: verseText,
                    maskedIndices: words.indices.filter { $0 % 2 == phase },
                    instruction: "Type the first letter of each missing word.",
                    showWordHints: true,
                    onContinue: advance,
                )
                .id(stepIndex)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .everyWord, .everyWordRetry:
                ActivityView(
                    activityName: "Every Word",
                    passage: passage,
                    verseText: verseText,
                    maskedIndices: Array(words.indices),
                    instruction: "Type the first letter of every word from memory.",
                    showWordHints: false,
                    onContinue: advance,
                )
                .id(stepIndex)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .verbalRecite:
                VerbalActivityView(
                    passage: passage,
                    verseText: verseText,
                    onContinue: advance,
                )
                .id(stepIndex)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
    }

    // MARK: - Non-activity phase views

    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading passage...")
                .font(.app(.subheadline))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func doneView(nextReview: Date?, correct: Int, total: Int) -> some View {
        VStack(spacing: AppSpacing.xxl) {
            Spacer()

            Image(systemName: correct == total ? "star.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(correct == total ? .yellow : .green)

            VStack(spacing: AppSpacing.sm) {
                Text("Session Complete!")
                    .font(.app(.title2, weight: .semibold))

                if total > 0 {
                    Text("\(correct) of \(total) correct")
                        .font(.app(.title3))
                        .foregroundStyle(scoreColor(correct: correct, total: total))
                }

                Text(scoreMessage(correct: correct, total: total))
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)

                if let nextReview {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "calendar")
                        Text("Next review: \(nextReview.formatted(.dateTime.month(.abbreviated).day().year()))")
                    }
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
                }
            }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.app(.body, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppRadius.md)
                    .background(Color.appAccent, in: RoundedRectangle(cornerRadius: AppRadius.md))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
    }

    private func failedView(message: String) -> some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Something went wrong")
                .font(.app(.title3, weight: .semibold))
            Text(message)
                .font(.app(.subheadline))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Dismiss") { dismiss() }
                .font(.app(.body, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, AppSpacing.xxl)
    }

    // MARK: - Score helpers

    private func scoreMessage(correct: Int, total: Int) -> String {
        guard total > 0 else { return "Good work!" }
        let pct = Double(correct) / Double(total)
        switch pct {
        case 1.0...: return "Perfect recall!"
        case 0.7...: return "Great job!"
        case 0.5...: return "Keep it up!"
        default: return "Practice makes perfect."
        }
    }

    private func scoreColor(correct: Int, total: Int) -> Color {
        guard total > 0 else { return .secondary }
        let pct = Double(correct) / Double(total)
        if pct >= 0.8 { return .green }
        if pct >= 0.5 { return .orange }
        return .red
    }

    // MARK: - Actions

    private func advance(correct: Int, total: Int) {
        let now = Date()
        let step = steps[stepIndex]

        collectedActivities.append(ActivityRecord(
            type: step.activityType,
            phase: step.phase,
            isRetry: step.isRetry,
            correctCount: correct,
            totalCount: total,
            startDate: stepStartDate,
            endDate: now,
        ))

        totalCorrect += correct
        totalPossible += total

        if case let .everyWord(allowsRetry) = step, allowsRetry, correct < total {
            withAnimation(.easeInOut(duration: 0.35)) {
                steps.insert(.everyWordRetry, at: stepIndex + 1)
            }
        }

        if stepIndex + 1 < steps.count {
            withAnimation(.easeInOut(duration: 0.3)) {
                stepIndex += 1
            }
            stepStartDate = now
        } else {
            completeSession()
        }
    }

    /// Fetches the verse text, then begins the standard activity plan.
    /// Nothing is persisted until the session completes, so abandoning is free.
    private func startSession() async {
        await bibleStore.fetchSelection(passage.selectionKey)
        guard !verseText.isEmpty else {
            phase = .failed("Couldn't load the passage text. Check your connection and try again.")
            return
        }
        steps = ActivityStep.standardPlan
        sessionStartDate = Date()
        stepStartDate = sessionStartDate
        phase = .activity
        log.info("Started practice session for passage \(passage.reference), \(steps.count) steps")
    }

    /// Applies the session to the passage's memory state via FSRS and persists
    /// the session + activities. All local — no network involved.
    private func completeSession() {
        let now = Date()
        let correct = totalCorrect
        let total = totalPossible
        let score = total > 0 ? Double(correct) / Double(total) : 0

        // Capture pre-review values the session record needs.
        let stateAtReview = passage.state
        let previousReview = passage.lastPracticed

        let outcome = scheduler.processReview(state: passage.memoryState, score: score, at: now)

        let session = PracticeSession(startDate: sessionStartDate)
        session.endDate = now
        session.score = score
        session.rating = outcome.rating
        session.scheduledDays = Int(outcome.intervalDays)
        session.elapsedDays = previousReview.map { max(0, Int(now.timeIntervalSince($0) / 86400)) } ?? 0
        session.state = stateAtReview
        session.passage = passage

        for (position, record) in collectedActivities.enumerated() {
            let activity = PracticeActivity(
                position: position,
                type: record.type,
                phase: record.phase,
                isRetry: record.isRetry,
                correctCount: record.correctCount,
                totalCount: record.totalCount,
                startDate: record.startDate,
                endDate: record.endDate,
            )
            activity.session = session
        }

        modelContext.insert(session)
        passage.memoryState = outcome.state

        do {
            try modelContext.save()
        } catch {
            log.error("Failed to save practice session: \(error)")
            phase = .failed("Couldn't save your progress: \(error.localizedDescription)")
            return
        }

        phase = .done(nextReview: outcome.state.due, correct: correct, total: total)
        log.info("""
        Completed session for \(passage.reference), \
        \(correct)/\(total) correct, \
        score=\(String(format: "%.2f", score)), \
        rating=\(outcome.rating)
        """)
    }
}

#Preview {
    SessionView(passage: PreviewData.samplePassage)
        .modelContainer(PreviewData.container)
        .environment(BibleStore.shared)
        .environment(\.font, .app())
}
