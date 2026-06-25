//
//  SessionView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/8/26.
//

import SwiftUI

private enum SessionPhase: Equatable {
    case loading
    case activity
    case completing
    case done(nextReview: Date?, correct: Int, total: Int)
    case failed(String)
}

struct SessionView: View {
    let passage: UserPassage

    @Environment(BibleStore.self) private var bibleStore
    @Environment(PassageStore.self) private var passageStore
    @Environment(PracticeStore.self) private var practiceStore
    @Environment(\.dismiss) private var dismiss

    @State private var phase: SessionPhase = .loading
    @State private var showAbandonConfirmation = false
    @State private var session: StartPracticeSessionResponse?
    @State private var steps: [ActivityStep] = []
    @State private var stepIndex = 0
    @State private var stepStartDate = Date()
    @State private var totalCorrect = 0
    @State private var totalPossible = 0
    @State private var collectedActivities: [ActivityResult] = []

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
                    fill: .solid(.accentColor),
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
                case .completing:
                    completingView
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
                                Task { await abandonSession() }
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
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
            Button("Quit", role: .destructive) { Task { await abandonSession() } }
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
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Starting session...")
                .font(.app(.subheadline))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var completingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Saving your progress...")
                .font(.app(.subheadline))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func doneView(nextReview: Date?, correct: Int, total: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: correct == total ? "star.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(correct == total ? .yellow : .green)

            VStack(spacing: 8) {
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
                    HStack(spacing: 6) {
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
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private func failedView(message: String) -> some View {
        VStack(spacing: 20) {
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
        .padding(.horizontal, 30)
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

        collectedActivities.append(ActivityResult(
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
            Task { await completeSession() }
        }
    }

    private func abandonSession() async {
        if let session {
            do {
                try await APIService.shared.deleteSession(id: session.id)
                log.info("Abandoned and deleted session \(session.id)")
            } catch {
                log.error("Failed to delete abandoned session \(session.id): \(error)")
            }
        }
        dismiss()
    }

    private func startSession() async {
        do {
            let resp = try await APIService.shared.startPracticeSession(passageId: passage.id)
            session = resp
            steps = resp.plan.compactMap { ActivityStep.from($0) }
            guard !steps.isEmpty else {
                phase = .failed("Session plan is empty")
                return
            }
            stepStartDate = Date()
            phase = .activity
            log.info("Started practice session \(resp.id) for passage \(passage.id), \(steps.count) steps")
        } catch {
            log.error("Failed to start session: \(error)")
            phase = .failed(error.localizedDescription)
        }
    }

    private func completeSession() async {
        guard let session else { return }
        let correct = totalCorrect
        let total = totalPossible
        let activities = collectedActivities
        phase = .completing
        do {
            let result = try await APIService.shared.completePracticeSession(
                id: session.id,
                activities: activities,
            )
            Task {
                await passageStore.loadMyPassages(lookInCache: false)
                await practiceStore.loadMyPracticeSessions()
            }
            phase = .done(nextReview: result.nextReview, correct: correct, total: total)
            let score = total > 0 ? Double(correct) / Double(total) : 0
            log.info("Completed session \(session.id), \(correct)/\(total) correct, score=\(String(format: "%.2f", score)), rating=\(result.rating)")
        } catch {
            log.error("Failed to complete session: \(error)")
            phase = .failed(error.localizedDescription)
        }
    }
}

#Preview {
    let passage = UserPassage(
        id: 1, userId: "test", book: "John",
        startChapter: 3, endChapter: 3, startVerse: 16, endVerse: 16,
        translation: "KJV",
        lastPracticed: nil, nextPractice: nil,
        stability: 1.0, difficulty: 5.0, state: 0,
        reps: 0, lapses: 0, scheduledDays: 0, elapsedDays: 0,
    )
    SessionView(passage: passage)
        .environment(BibleStore.shared)
        .environment(PassageStore.shared)
        .environment(PracticeStore.shared)
        .environment(\.font, .app())
}
