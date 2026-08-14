//
//  RecitationRecorder.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 8/9/26.
//

import AVFoundation
import Observation
import Speech

/// Drives the recite step's mic UI.
///
/// `unavailable` carries no reason: every cause — no mic, denied permission,
/// missing model, nothing heard — leads to the same thing, skipping the step,
/// and each one already logs what happened where it occurs.
enum RecitationState: Equatable {
    case idle
    case requestingPermission
    case downloadingModel
    case recording(volatileText: String)
    case finished(transcript: String)
    case unavailable
}

private enum RecitationAudioError: Error {
    case converterUnavailable
    case assetsUnsupported
}

/// Captures the mic, transcribes on-device with `SpeechAnalyzer`, and
/// publishes live/finalized text for the "Verbal Recite" step. Scoped to a
/// single recite step's lifetime — instantiated as local `@State` by
/// `VerbalActivityView`, not a shared environment store. Every failure mode
/// (permission, missing locale model, no speech) publishes `.unavailable`
/// rather than throwing; callers only ever branch on `state`.
@Observable
@MainActor
final class RecitationRecorder {
    private(set) var state: RecitationState = .idle
    /// Normalized mic input level (0...1), updated straight from the audio
    /// tap. Transcription results lag speech by design, so this is what the
    /// UI leans on to feel live while the transcriber catches up.
    private(set) var audioLevel: Double = 0

    private let log = AppLog.category("RecitationRecorder")

    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var audioEngine: AVAudioEngine?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var resultsTask: Task<Void, Never>?
    private var finalizedTranscript = ""
    /// Loudest amplitude seen recently, used to auto-scale `audioLevel`.
    private var referencePeak: Double = 0

    /// Requests mic + speech permission, resolves and (if needed) downloads
    /// the locale's on-device model, and starts recording. Never throws —
    /// any failure lands on `.unavailable`.
    func start(locale: Locale = .current) async {
        state = .requestingPermission

        guard SpeechTranscriber.isAvailable else {
            log.warning("SpeechTranscriber unavailable on this device")
            state = .unavailable
            return
        }
        guard await requestSpeechAuthorization() else {
            log.info("Speech recognition permission denied")
            state = .unavailable
            return
        }
        guard await AVAudioApplication.requestRecordPermission() else {
            log.info("Microphone permission denied")
            state = .unavailable
            return
        }

        guard let resolvedLocale = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else {
            log.warning("No supported transcription locale for \(locale.identifier)")
            state = .unavailable
            return
        }

        let transcriber = SpeechTranscriber(
            locale: resolvedLocale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [],
        )

        do {
            try await installAssetsIfNeeded(for: transcriber, locale: resolvedLocale)
        } catch {
            log.error("Model asset install failed: \(error.localizedDescription)")
            state = .unavailable
            return
        }

        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            log.error("No compatible audio format for transcriber")
            state = .unavailable
            return
        }

        self.transcriber = transcriber
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer

        let (inputSequence, continuation) = AsyncStream<AnalyzerInput>.makeStream(of: AnalyzerInput.self)
        inputContinuation = continuation

        do {
            try startAudioEngine(targetFormat: analyzerFormat, continuation: continuation)
        } catch {
            log.error("Audio engine start failed: \(error.localizedDescription)")
            teardownAudio()
            state = .unavailable
            return
        }

        finalizedTranscript = ""
        consumeResults(from: transcriber)

        do {
            try await analyzer.start(inputSequence: inputSequence)
        } catch {
            log.error("Analyzer start failed: \(error.localizedDescription)")
            teardownAudio()
            state = .unavailable
            return
        }

        state = .recording(volatileText: "")
    }

    /// Stops capture and waits for the transcript to finalize, landing on
    /// `.finished(transcript:)` — or `.unavailable` if nothing was captured.
    func stop() async {
        guard case .recording = state else { return }
        log.info("Stopping recitation recording")

        teardownAudio()

        do {
            try await analyzer?.finalizeAndFinishThroughEndOfInput()
        } catch {
            log.error("Analyzer finalize failed: \(error.localizedDescription)")
        }

        await resultsTask?.value
        resultsTask = nil
        analyzer = nil
        transcriber = nil

        let transcript = finalizedTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        if transcript.isEmpty {
            log.info("No speech captured — skipping recite step")
            state = .unavailable
        } else {
            // Word count only; the transcript itself is never logged.
            let wordCount = transcript.split(whereSeparator: \.isWhitespace).count
            log.info("Recitation finished: \(wordCount) words transcribed")
            state = .finished(transcript: transcript)
        }
    }

    /// Immediate teardown without waiting for finalization — call whenever
    /// the recite step is left, backgrounded, or the session is abandoned,
    /// so a stale analyzer never lingers against iOS's ~2-instance cap on
    /// the next recite step.
    func cancel() {
        guard state != .idle else { return }
        log.info("Cancelling recitation recorder")

        teardownAudio()
        resultsTask?.cancel()
        resultsTask = nil

        let analyzerToFinish = analyzer
        analyzer = nil
        transcriber = nil
        state = .idle

        Task.detached {
            await analyzerToFinish?.cancelAndFinishNow()
        }
    }

    /// Whether recitation already can't work, determined without prompting
    /// for anything — all three of these are plain getters.
    ///
    /// Undetermined permissions deliberately count as *available*: the only
    /// way to resolve those is to ask, and asking belongs behind the user
    /// tapping Start, not behind the step merely appearing.
    static var isKnownUnavailable: Bool {
        guard SpeechTranscriber.isAvailable else { return true }
        switch SFSpeechRecognizer.authorizationStatus() {
        case .denied, .restricted: return true
        default: break
        }
        return AVAudioApplication.shared.recordPermission == .denied
    }

    #if DEBUG
        /// A recorder parked mid-recording, for previews. The simulator can't
        /// run `SpeechTranscriber` at all, so this is the only way to see the
        /// listening UI without a device.
        static func previewRecording(text: String, level: Double) -> RecitationRecorder {
            let recorder = RecitationRecorder()
            recorder.state = .recording(volatileText: text)
            recorder.audioLevel = level
            return recorder
        }
    #endif

    // MARK: - Model assets

    /// Ensures the locale's on-device transcription model is installed.
    ///
    /// The locale reservation is not optional in practice: despite what
    /// `assetInstallationRequest(supporting:)` documents about reserving
    /// automatically, without an explicit `reserve(locale:)` the install
    /// fails with "… is not subscribed to transcription.<language>".
    private func installAssetsIfNeeded(for transcriber: SpeechTranscriber, locale: Locale) async throws {
        let status = await AssetInventory.status(forModules: [transcriber])
        if status == .installed { return }
        if status == .unsupported { throw RecitationAudioError.assetsUnsupported }

        let reserved = await AssetInventory.reservedLocales
        if !reserved.contains(where: { $0.identifier == locale.identifier }) {
            log.info("Reserving transcription locale \(locale.identifier)")
            try await AssetInventory.reserve(locale: locale)
        }

        log.info("Installing on-device model for \(locale.identifier)")
        state = .downloadingModel
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await request.downloadAndInstall()
        }
    }

    // MARK: - Permissions

    private func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: - Results consumption

    private func consumeResults(from transcriber: SpeechTranscriber) {
        resultsTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await result in transcriber.results {
                    let text = String(result.text.characters)
                    if result.isFinal {
                        finalizedTranscript = finalizedTranscript.isEmpty ? text : "\(finalizedTranscript) \(text)"
                        state = .recording(volatileText: finalizedTranscript)
                    } else {
                        let live = finalizedTranscript.isEmpty ? text : "\(finalizedTranscript) \(text)"
                        state = .recording(volatileText: live)
                    }
                }
            } catch {
                log.error("Transcription results stream failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Audio capture

    private func startAudioEngine(
        targetFormat: AVAudioFormat,
        continuation: AsyncStream<AnalyzerInput>.Continuation,
    ) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [])
        try session.setActive(true)

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard let converter = AVAudioConverter(from: recordingFormat, to: targetFormat) else {
            throw RecitationAudioError.converterUnavailable
        }

        // Smaller buffers than the analyzer strictly needs: ~21ms each, so
        // the level meter updates ~45×/sec and tracks speech instead of
        // lagging a syllable behind it.
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            let amplitude = RecitationRecorder.peakAmplitude(of: buffer)
            Task { @MainActor in self?.apply(amplitude: amplitude) }

            let ratio = targetFormat.sampleRate / recordingFormat.sampleRate
            let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 16
            guard let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: capacity,
            ) else { return }

            var conversionError: NSError?
            var consumed = false
            converter.convert(to: convertedBuffer, error: &conversionError) { _, inputStatus in
                if consumed {
                    inputStatus.pointee = .noDataNow
                    return nil
                }
                consumed = true
                inputStatus.pointee = .haveData
                return buffer
            }

            guard conversionError == nil else { return }
            continuation.yield(AnalyzerInput(buffer: convertedBuffer))
        }

        engine.prepare()
        try engine.start()
        audioEngine = engine
    }

    /// Loudest sample in the buffer, 0...1 linear.
    ///
    /// Peak rather than RMS: `bufferSize` on a tap is only a hint and the
    /// engine routinely hands back ~100ms of audio, over which RMS averages
    /// a whole syllable into a single number — precisely the variation the
    /// meter is supposed to show. Runs on the audio thread; keep it cheap.
    private nonisolated static func peakAmplitude(of buffer: AVAudioPCMBuffer) -> Double {
        guard let samples = buffer.floatChannelData?[0] else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }

        var peak: Float = 0
        for index in 0 ..< count {
            peak = max(peak, abs(samples[index]))
        }
        return Double(peak)
    }

    /// Turns a raw amplitude into the 0...1 the UI pulses on.
    ///
    /// Normalizing against a slowly-decaying running peak rather than a
    /// fixed dB window means the meter uses its full range whatever input
    /// gain the device happens to give us — no guessing where speech lands
    /// on an absolute scale, which is how this ended up pinned before.
    ///
    /// Attack is immediate and release is quick (not slow): with a slow
    /// release, continuous speech re-triggers the attack before the level
    /// can fall, so the dot just sits at maximum the whole time you talk
    /// and reads as dead.
    private func apply(amplitude: Double) {
        referencePeak = max(amplitude, referencePeak * 0.995)

        // Below roughly -40 dBFS is room tone; normalizing that would
        // amplify silence into a full-scale pulse.
        let normalized = referencePeak > 0.01 ? min(amplitude / referencePeak, 1) : 0
        audioLevel = normalized > audioLevel
            ? normalized
            : audioLevel * 0.55 + normalized * 0.45
    }

    private func teardownAudio() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioLevel = 0
        referencePeak = 0

        inputContinuation?.finish()
        inputContinuation = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
