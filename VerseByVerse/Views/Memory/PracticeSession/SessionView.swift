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
    case preview
    case activity
    case done(nextReview: Date?, correct: Int, total: Int)
    case failed(String)
    case loadFailed
}

/// Runs a practice session over an ordered list of verses — a whole passage
/// or a single standalone verse. Every verse gets its own FSRS review at
/// completion; nothing is persisted for abandoned sessions.
struct SessionView: View {
    private let verses: [Verse]
    private let title: String
    private let passage: Passage?
    private let standaloneVerse: Verse?

    @Environment(BibleStore.self) private var bibleStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var phase: SessionPhase = .loading
    @State private var loadAttempt = 0
    @State private var showAbandonConfirmation = false
    @State private var sessionStartDate = Date()
    @State private var steps: [ActivityStep] = []
    @State private var stepIndex = 0
    @State private var stepStartDate = Date()
    @State private var collectedActivities: [ActivityRecord] = []
    /// Scored results only (see ``ActivityStep/isScored``).
    @State private var tally = SessionTally()

    private let scheduler = FSRSScheduler()
    private let log = AppLog.category("SessionView")

    init(passage: Passage) {
        verses = passage.orderedVerses
        title = passage.reference
        self.passage = passage
        standaloneVerse = nil
    }

    init(verse: Verse) {
        verses = [verse]
        title = verse.reference
        passage = nil
        standaloneVerse = verse
    }

    private var selectionKey: BibleSelectionKey? {
        if let passage {
            return passage.selectionKey
        }
        return standaloneVerse?.selectionKey
    }

    private var translationInfo: BibleTranslationInfo {
        bibleStore.translationInfo(forAbbreviation: selectionKey?.translation ?? "")
    }

    private var verseText: String {
        selectionKey.flatMap { bibleStore.selections[$0]?.fullText } ?? ""
    }

    private var words: [String] {
        verseText.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    }

    private var loadError: APIError? {
        selectionKey.flatMap { bibleStore.selectionState(for: $0).apiError }
    }

    private var canDismiss: Bool {
        phase == .loading || phase == .preview || phase == .activity
    }

    var body: some View {
        NavigationStack {
            if phase == .preview || phase == .activity {
                SegmentedProgressBar(
                    totalSegments: steps.count,
                    completedSegments: phase == .activity ? stepIndex : 0,
                    fill: .solid(.appAccent),
                    highlightCurrent: phase == .activity,
                    accessibilityLabel: "Session progress",
                    accessibilityValue: phase == .activity ? "Step \(stepIndex + 1) of \(steps.count)" : "Not started",
                )
                .padding(.horizontal)
            }
            Group {
                switch phase {
                case .loading:
                    loadingView
                case .preview:
                    SessionPreviewView(steps: steps, onStart: beginSession)
                case .activity:
                    activityContent
                case let .done(nextReview, correct, total):
                    SessionCompleteView(nextReview: nextReview, correct: correct, total: total, onDone: { dismiss() })
                case let .failed(msg):
                    failedView(message: msg)
                case .loadFailed:
                    LoadFailureView(
                        title: "Can't Load Verse Text",
                        error: loadError,
                        offlineMessage: "Connect to the internet to load the verse text and practice.",
                        onRetry: retryLoad,
                        onClose: { dismiss() },
                    )
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
                        .accessibilityLabel("Close session")
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.app(.headline))
                }
            }
        }
        .task(id: loadAttempt) {
            await startSession()
        }
        .retryWhenOnline(if: phase == .loadFailed) { retryLoad() }
        .retryAfterRateLimit(error: { phase == .loadFailed ? loadError : nil }) { retryLoad() }
        .alert("Quit Session?", isPresented: $showAbandonConfirmation) {
            Button("Quit", role: .destructive) { dismiss() }
            Button("Continue", role: .cancel) {}
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
                    step: steps[stepIndex],
                    translation: translationInfo,
                    passageText: verseText,
                    maskedIndices: TypingProgress.everyOtherIndices(in: words, phase: phase),
                    instruction: "Type the first letter of each missing word. This warm-up isn't scored.",
                    onContinue: advance,
                )
                .id(stepIndex)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .everyWord, .everyWordRetry:
                ActivityView(
                    step: steps[stepIndex],
                    translation: translationInfo,
                    passageText: verseText,
                    maskedIndices: TypingProgress.typeableIndices(in: words),
                    instruction: steps[stepIndex].isRetry
                        ? "Type the first letter of every word from memory. This retry isn't scored."
                        : "Type the first letter of every word from memory.",
                    onContinue: advance,
                )
                .id(stepIndex)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .verbalRecite:
                VerbalActivityView(
                    translation: translationInfo,
                    passageWords: words,
                    onContinue: advance,
                    onSkip: skipStep,
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

    private func failedView(message: String) -> some View {
        ContentUnavailableView {
            Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Close") { dismiss() }
        }
    }

    // MARK: - Actions

    /// Moves past a step without recording an activity or any score — either
    /// because spoken recitation can't run (mic denied, model unavailable, no
    /// speech captured) or because the user chose to skip it. The step simply
    /// didn't happen; nothing is penalized.
    private func skipStep() {
        let step = steps[stepIndex]
        log.info("Skipping \(step.activityType)")

        if stepIndex + 1 < steps.count {
            withAnimation(.easeInOut(duration: 0.3)) {
                stepIndex += 1
            }
            stepStartDate = Date()
        } else {
            completeSession()
        }
    }

    private func advance(correct: Int, total: Int, perWord: [Int: Bool]) {
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

        tally.record(step: step, correct: correct, total: total, perWord: perWord)

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

    /// Fetches the verse text, maps each word to its verse, and shows the
    /// preview. Nothing persists until the session completes.
    private func startSession() async {
        guard let selectionKey, !verses.isEmpty else {
            phase = .failed("Nothing to practice.")
            return
        }
        await bibleStore.fetchSelection(selectionKey)
        guard let selection = bibleStore.selections[selectionKey], !selection.fullText.isEmpty else {
            phase = .loadFailed
            return
        }

        tally = SessionTally(
            verseCount: verses.count,
            wordOwners: Self.mapWordsToVerses(selection: selection, verses: verses),
        )

        steps = ActivityStep.standardPlan
        phase = .preview
        FUMSReporter.shared.report(tokens: selection.fumsTokens)
        log.info("Loaded session for \(title): \(verses.count) verses, \(steps.count) steps")
    }

    /// Shows the spinner again and re-runs the load.
    private func retryLoad() {
        phase = .loading
        loadAttempt += 1
    }

    /// Leaves the preview and starts the first activity.
    private func beginSession() {
        sessionStartDate = Date()
        stepStartDate = sessionStartDate
        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .activity
        }
        log.info("Started session for \(title)")
    }

    /// Builds word index → verse index using the per-verse texts of the
    /// fetched selection, aligned with `fullText`'s word order.
    static func mapWordsToVerses(selection: BibleSelection, verses: [Verse]) -> [Int] {
        // Position of each tracked verse by (chapter, number) for alignment.
        var verseIndexByRef: [String: Int] = [:]
        for (index, verse) in verses.enumerated() {
            verseIndexByRef["\(verse.chapter):\(verse.number)"] = index
        }

        var owners: [Int] = []
        for selectionVerse in selection.verses {
            let wordCount = selectionVerse.text
                .split(separator: " ", omittingEmptySubsequences: true).count
            // Fall back to the last verse if refs don't line up (defensive).
            let owner = verseIndexByRef["\(selectionVerse.chapter):\(selectionVerse.verse)"]
                ?? max(0, verses.count - 1)
            owners.append(contentsOf: Array(repeating: owner, count: wordCount))
        }
        return owners
    }

    /// Applies one FSRS review per verse and persists the session, its
    /// activities, and one `VerseReview` per verse — all in a single save.
    private func completeSession() {
        let now = Date()
        let correct = tally.correct
        let total = tally.total
        let pooledScore = total > 0 ? Double(correct) / Double(total) : 0

        let session = PracticeSession(startDate: sessionStartDate)
        session.endDate = now
        session.score = pooledScore
        session.rating = MemoryScoring.rating(forScore: pooledScore)
        session.passage = passage
        session.standaloneVerse = standaloneVerse

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

        var longestIntervalDays = 0.0
        for (index, verse) in verses.enumerated() {
            let verseCorrect = tally.verseCorrect[index]
            let verseTotal = tally.verseTotal[index]
            guard let verseScore = MemoryScoring.score(correct: verseCorrect, total: verseTotal) else {
                // No words were scored for this verse, so there's nothing to
                // judge: no review, no lapse, schedule untouched.
                log.info("Skipping review for \(verse.reference): no scored words")
                continue
            }
            let outcome = scheduler.processReview(state: verse.memoryState, score: verseScore, at: now)

            let review = VerseReview(reviewedAt: now)
            review.correctCount = verseCorrect
            review.totalCount = verseTotal
            review.score = verseScore
            review.rating = outcome.rating
            review.stabilityAfter = outcome.state.stability ?? 0
            review.difficultyAfter = outcome.state.difficulty ?? 0
            review.stateAfter = outcome.state.state
            review.verse = verse
            review.session = session

            verse.memoryState = outcome.state
            longestIntervalDays = max(longestIntervalDays, outcome.intervalDays)
        }
        session.scheduledDays = Int(longestIntervalDays)

        modelContext.insert(session)

        do {
            try modelContext.save()
        } catch {
            log.error("Failed to save practice session: \(error)")
            phase = .failed("Couldn't save your progress: \(error.localizedDescription)")
            return
        }

        let nextReview = verses.compactMap(\.nextPractice).min()
        phase = .done(nextReview: nextReview, correct: correct, total: total)
        log.info("""
        Completed session for \(title): \(correct)/\(total) pooled, \
        \(verses.count) verse reviews written
        """)
    }
}

#Preview {
    if let passage = PreviewData.passages.first {
        SessionView(passage: passage)
            .modelContainer(PreviewData.container)
            .environment(BibleStore.shared)
            .environment(\.font, .app())
    }
}
