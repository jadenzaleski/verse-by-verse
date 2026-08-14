//
//  VerbalActivityView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/8/26.
//

import SwiftUI

/// The spoken recite step: record the user saying the verse aloud, transcribe
/// it on-device, and grade the transcript word-by-word against the passage.
/// If the mic or transcription isn't usable for any reason, the step is
/// skipped outright — no score, no penalty.
struct VerbalActivityView: View {
    let reference: String
    /// Raw passage words, graded against the finalized transcript.
    let passageWords: [String]
    /// Called with (correct, total, per-word correctness keyed by word index).
    let onContinue: (Int, Int, [Int: Bool]) -> Void
    /// Called instead of `onContinue` when the step is passed over — either
    /// because recitation can't run, or because the user chose to skip it.
    let onSkip: () -> Void

    @State private var recorder = RecitationRecorder()
    #if DEBUG
        /// Stands in for a real transcript so the grading UI is reachable on
        /// the simulator, where `SpeechTranscriber` is never available.
        @State private var debugTranscript: String?
    #endif

    private enum Mode: Equatable {
        case idle
        case preparing
        case recording
        case reviewing
    }

    /// Derived from the recorder rather than mirrored into `@State`: the
    /// recording case carries live volatile text that changes many times per
    /// frame, and writing each of those through `onChange` would thrash
    /// state SwiftUI can just read.
    private var mode: Mode {
        #if DEBUG
            if debugTranscript != nil { return .reviewing }
        #endif
        switch recorder.state {
        case .idle, .unavailable: return .idle
        case .requestingPermission, .downloadingModel: return .preparing
        case .recording: return .recording
        case .finished: return .reviewing
        }
    }

    private var grader: RecitationGrader? {
        #if DEBUG
            if let debugTranscript {
                return RecitationGrader(expectedWords: passageWords, transcript: debugTranscript)
            }
        #endif
        guard case let .finished(transcript) = recorder.state else { return nil }
        return RecitationGrader(expectedWords: passageWords, transcript: transcript)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    header
                    switch mode {
                    case .idle:
                        idleContent
                    case .preparing:
                        preparingContent
                    case .recording:
                        recordingContent
                    case .reviewing:
                        if let grader {
                            reviewingContent(grader: grader)
                        }
                    }
                }
                .padding(AppSpacing.xl)
                .padding(.top, AppSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeIn(duration: 0.2), value: mode)
            }

            controls
        }
        .task {
            // Skip before offering a Start button that could only dead-end.
            // Permissions we haven't asked for yet don't count — those get
            // resolved by tapping Start, not by arriving here.
            if RecitationRecorder.isKnownUnavailable { onSkip() }
        }
        .onChange(of: recorder.state == .unavailable) { _, unavailable in
            if unavailable { onSkip() }
        }
        .onDisappear { recorder.cancel() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: AppSpacing.sm) {
            Text("Verbal Recite")
                .font(.app(.caption, weight: .semibold))
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(Color.appAccent.opacity(0.15), in: Capsule())
                .foregroundStyle(Color.appAccent)
            Spacer()
            Text(reference)
                .font(.app(.caption))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Content by mode

    private var idleContent: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "mic.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.appAccent)
            Text("Say the verse aloud from memory.")
                .font(.app(.title3, weight: .semibold))
                .multilineTextAlignment(.center)
            Text("Tap Start, recite the verse, then tap Done.")
                .font(.app(.subheadline))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.xxl)
    }

    private var preparingContent: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .scaleEffect(1.3)
            Text(recorder.state == .downloadingModel ? "Downloading language model…" : "Getting ready…")
                .font(.app(.subheadline))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.xxl)
    }

    private var recordingContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // One pulse at a time: "Listening…" holds the screen until the
            // first words land, then the caret trailing the transcript takes
            // over as the sign we're still hearing you.
            if volatileWords.isEmpty {
                ListeningIndicator(recorder: recorder)
            } else {
                // Words flow through the same layout the graded review uses,
                // so the caret lands inline after the last word rather than
                // below the whole block.
                FlowLayout(spacing: 6, lineSpacing: 10) {
                    ForEach(Array(volatileWords.enumerated()), id: \.offset) { _, word in
                        Text(word)
                            .bibleWordStyle()
                            .foregroundStyle(.secondary)
                    }
                    LiveCaret(recorder: recorder)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppSpacing.lg)
    }

    private var volatileWords: [String] {
        guard case let .recording(volatileText) = recorder.state else { return [] }
        return volatileText.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    private func reviewingContent(grader: RecitationGrader) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            FlowLayout(spacing: 6, lineSpacing: 10) {
                ForEach(Array(passageWords.enumerated()), id: \.offset) { index, word in
                    GradedWordCell(word: word, isCorrect: grader.perWordCorrectness[index] ?? false)
                }
            }

            HStack(spacing: AppSpacing.xs) {
                Text("\(grader.correctCount) of \(grader.totalCount)")
                    .font(.app(.body, weight: .semibold))
                    .foregroundStyle(grader.correctCount == grader.totalCount ? Color.appSuccess : Color.appAccent)
                Text("correct")
                    .font(.app(.body))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Controls by mode

    private var controls: some View {
        VStack(spacing: AppSpacing.md) {
            switch mode {
            case .idle:
                HStack(spacing: AppSpacing.md) {
                    Button("Start") {
                        Task { await recorder.start() }
                    }
                    .buttonStyle(.primary)

                    Button("Skip", action: onSkip)
                        .buttonStyle(.outlined)
                }
            case .preparing:
                EmptyView()
            case .recording:
                Button("Done") {
                    Task { await recorder.stop() }
                }
                .buttonStyle(.primary(.appDestructive))
            case .reviewing:
                if let grader {
                    Button("Continue") {
                        onContinue(grader.correctCount, grader.totalCount, grader.perWordCorrectness)
                    }
                    .buttonStyle(.primary)
                }
            }

            #if DEBUG
                if mode != .reviewing {
                    Button("Fake a recitation (debug)") {
                        // Drop every 4th word so the graded review shows both
                        // hit and miss coloring.
                        debugTranscript = passageWords.enumerated()
                            .filter { $0.offset % 4 != 3 }
                            .map(\.element)
                            .joined(separator: " ")
                    }
                    .font(.app(.caption))
                    .foregroundStyle(.tertiary)
                }
            #endif
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, 30)
    }
}

/// The pulse behind both the "Listening…" dot and the caret trailing the
/// live transcript — one implementation, two tints.
///
/// The halo is driven purely by mic level so it visibly tracks your voice;
/// the core keeps a slow breath of its own so a silent moment never looks
/// like a frozen screen. Reads `recorder.audioLevel` in its own body, so
/// the ~45×/sec level updates invalidate only this dot rather than the
/// whole activity view.
private struct PulsingDot: View {
    let recorder: RecitationRecorder
    let color: Color
    var size: CGFloat = 26

    @State private var breathing = false

    var body: some View {
        let level = recorder.audioLevel
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size, height: size)
                .scaleEffect(0.35 + level * 0.95)
                // Short enough to read as reaction rather than easing —
                // the level itself is already smoothed on the way in.
                .animation(.easeOut(duration: 0.05), value: level)

            Circle()
                .fill(color)
                .frame(width: size * 0.4, height: size * 0.4)
                .scaleEffect(breathing ? 1.1 : 0.85)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: breathing)
                // Stacked on top of the breath so the core moves with your
                // voice too, rather than leaving all the reaction to the halo.
                .scaleEffect(1 + level * 0.35)
                .animation(.easeOut(duration: 0.05), value: level)
        }
        .frame(width: size, height: size)
        .onAppear { breathing = true }
    }
}

/// Shown only before the first words land — once the transcript starts,
/// `LiveCaret` takes over as the sign we're still listening.
private struct ListeningIndicator: View {
    let recorder: RecitationRecorder

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            PulsingDot(recorder: recorder, color: .appDestructive)
            Text("Listening…")
                .font(.app(.subheadline, weight: .semibold))
                .foregroundStyle(Color.appDestructive)
        }
    }
}

/// The caret trailing the live transcript.
private struct LiveCaret: View {
    let recorder: RecitationRecorder

    var body: some View {
        ZStack {
            // `FlowLayout` places every subview at its row's top edge, so a
            // bare dot rides high above the words. Matching a word's line
            // height (and tracking Dynamic Type) centers it on the text.
            Text("  ")
                .bibleWordStyle()
                .hidden()

            PulsingDot(recorder: recorder, color: .appAccent, size: 20)
        }
        // Narrower than the dot so the halo can swell past it without
        // pushing the words around.
        .frame(width: 12)
    }
}

/// A single word tile in the post-recording review screen, colored by
/// whether it was recognized in the recitation — unlike `TypedWordCell`,
/// there's no per-letter typed state to render here, just the whole word.
private struct GradedWordCell: View {
    let word: String
    let isCorrect: Bool

    var body: some View {
        Text(word)
            .bibleWordStyle()
            .foregroundStyle(isCorrect ? Color.appSuccess : Color.appDestructive)
    }
}

#Preview {
    VerbalActivityView(
        reference: "John 3:16",
        passageWords: """
        For God so loved the world that he gave his one and only \
        Son, that whoever believes in him shall not perish but have \
        eternal life.
        """.split(separator: " ").map(String.init),
        onContinue: { _, _, _ in },
        onSkip: {},
    )
    .environment(\.font, .app())
}

#Preview("Listening") {
    let recorder = RecitationRecorder.previewRecording(
        text: "For God so loved the world that he",
        level: 0.7,
    )
    return VStack(alignment: .leading, spacing: AppSpacing.md) {
        ListeningIndicator(recorder: recorder)
        FlowLayout(spacing: 6, lineSpacing: 10) {
            ForEach(["For", "God", "so", "loved", "the", "world", "that", "he"], id: \.self) { word in
                Text(word)
                    .bibleWordStyle()
                    .foregroundStyle(.secondary)
            }
            LiveCaret(recorder: recorder)
        }
    }
    .padding(AppSpacing.xl)
    .environment(\.font, .app())
}
