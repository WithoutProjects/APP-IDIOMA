import AVFoundation
import Speech

/// Listens to the learner speaking Spanish. Uses on-device recognition whenever the phone
/// supports it, so the voice does not leave the phone.
@MainActor
final class SpeechListener: ObservableObject {
    enum Status {
        case idle, listening, denied, unavailable
    }

    @Published private(set) var transcript = ""
    @Published private(set) var status = Status.idle
    /// True once recognition has finished the last attempt, so the answer can be checked.
    @Published private(set) var isFinal = false
    /// Words the recogniser was unsure of in the final transcript: usually the ones to say more clearly.
    @Published private(set) var unclearWords: [String] = []

    /// Below this confidence (0 to 1) a recognised word counts as unclear.
    static let clearConfidence: Float = 0.5
    /// Counts attempts, so a late result from an old attempt is ignored.
    private var attempt = 0

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    /// Asks for speech recognition and the microphone the first time; false if either is refused.
    func requestPermission() async -> Bool {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
        }
        let microphone = speech ? await AVAudioApplication.requestRecordPermission() : false
        if !(speech && microphone) { status = .denied }
        return speech && microphone
    }

    func start() async {
        guard await requestPermission() else { return }
        guard let recognizer, recognizer.isAvailable else {
            status = .unavailable
            return
        }
        stop()
        transcript = ""
        unclearWords = []
        isFinal = false
        attempt += 1
        let current = attempt
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }
            self.request = request

            let input = engine.inputNode
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
                request.append(buffer)
            }
            engine.prepare()
            try engine.start()
            status = .listening

            let clear = Self.clearConfidence
            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                let text = result?.bestTranscription.formattedString
                let done = error != nil || (result?.isFinal ?? false)
                // Confidence is only filled in on the final result; partial results report 0.
                let unclear = (result?.isFinal ?? false)
                    ? result?.bestTranscription.segments
                        .filter { $0.confidence > 0 && $0.confidence < clear }
                        .map(\.substring) ?? []
                    : []
                Task { @MainActor in
                    guard let self, self.attempt == current else { return }
                    if let text { self.transcript = text }
                    if done {
                        self.unclearWords = unclear
                        self.isFinal = true
                        self.stop()
                    }
                }
            }
        } catch {
            stop()
            status = .unavailable
        }
    }

    /// Stops and clears what was heard, for the next sentence.
    func reset() {
        attempt += 1
        stop()
        transcript = ""
        unclearWords = []
        isFinal = false
        if status != .denied { status = .idle }
    }

    /// Stops listening. The final result usually follows within a moment; if it doesn't,
    /// what was heard so far counts.
    func stop() {
        if status == .listening {
            let current = attempt
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(1.5))
                guard let self, self.attempt == current, !self.isFinal else { return }
                self.isFinal = true
            }
        }
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        request = nil
        task?.finish()
        task = nil
        if status == .listening { status = .idle }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
