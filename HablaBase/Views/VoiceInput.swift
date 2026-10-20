import SwiftUI

/// The big round button that starts and stops listening.
struct MicButton: View {
    @ObservedObject var listener: SpeechListener
    var size: CGFloat = 88

    var body: some View {
        let listening = listener.status == .listening
        Button {
            if listening {
                listener.stop()
            } else {
                Task { await listener.start() }
            }
        } label: {
            Image(systemName: listening ? "stop.fill" : "mic.fill")
                .font(size > 70 ? .largeTitle : .title)
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(listening ? Palette.warning : Brick.stem.color))
        }
        .accessibilityLabel(listening ? LocalizedStringKey("Stop") : LocalizedStringKey("Speak"))
    }
}

/// What the listener is doing, or why it can't listen.
struct SpeechStatusNote: View {
    @ObservedObject var listener: SpeechListener

    var body: some View {
        switch listener.status {
        case .listening:
            Text("Listening… tap stop when you finish.").foregroundStyle(.secondary)
        case .denied:
            VStack(alignment: .leading, spacing: 8) {
                Text("To practise speaking, allow the microphone and speech recognition in Settings.")
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link("Open Settings", destination: url)
                }
            }
        case .unavailable:
            Text("Speech recognition isn't available right now. Check your connection or try again later.")
                .foregroundStyle(.secondary)
        case .idle:
            EmptyView()
        }
    }
}

/// Exercises where the learner produces Spanish can be answered by typing or out loud.
/// The choice is remembered for the next exercises.
struct AnswerModePicker: View {
    @Binding var byVoice: Bool

    var body: some View {
        Picker("Answer by", selection: $byVoice) {
            Text("Write").tag(false)
            Text("Speak").tag(true)
        }
        .pickerStyle(.segmented)
    }
}

/// Answer out loud: what was heard goes into `text`, so Check grades it like a typed answer.
struct VoiceAnswerView: View {
    @Binding var text: String
    @StateObject private var listener = SpeechListener()

    var body: some View {
        VStack(spacing: 12) {
            MicButton(listener: listener, size: 72)
            if listener.transcript.isEmpty {
                if listener.status == .idle {
                    Text("Tap the microphone and say your answer in Spanish.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("I heard:").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    Text(listener.transcript).font(.title3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            SpeechStatusNote(listener: listener)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))
        // Only a finished attempt counts: Check stays off while listening.
        .onChange(of: listener.isFinal) { _, done in text = done ? listener.transcript : "" }
        .onChange(of: listener.status) { _, status in if status == .listening { text = "" } }
        .onDisappear { listener.stop() }
    }
}
