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

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                let text = result?.bestTranscription.formattedString
                let done = error != nil || (result?.isFinal ?? false)
                Task { @MainActor in
                    if let text { self?.transcript = text }
                    if done { self?.stop() }
                }
            }
        } catch {
            stop()
            status = .unavailable
        }
    }

    /// Stops and clears what was heard, for the next sentence.
    func reset() {
        stop()
        transcript = ""
        if status != .denied { status = .idle }
    }

    func stop() {
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
