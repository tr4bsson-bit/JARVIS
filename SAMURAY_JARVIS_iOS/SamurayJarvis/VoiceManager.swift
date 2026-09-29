import Foundation
import Speech
import AVFoundation

@MainActor
final class VoiceManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var transcript = ""
    @Published var response = "Toque no microfone para conversar."
    @Published var listening = false
    @Published var serverURL = ""
    @Published var accessToken = ""
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
    private let audioEngine = AVAudioEngine()
    private let speaker = AVSpeechSynthesizer()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var isProcessing = false

    override init() { super.init(); speaker.delegate = self }

    func toggle() { listening ? stop() : Task { await start() } }

    private func start() async {
        guard !listening else { return }
        let authorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard authorized else { response = "Autorize o reconhecimento de fala nas configurações."; return }
        let microphone = await AVAudioApplication.requestRecordPermission()
        guard microphone else { response = "Autorize o microfone nas configurações."; return }
        guard let recognizer, recognizer.isAvailable else { response = "Reconhecimento de fala indisponível no momento."; return }
        do {
            speaker.stopSpeaking(at: .immediate)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .duckOthers])
            try session.setActive(true)
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            self.request = request
            let input = audioEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
            audioEngine.prepare()
            try audioEngine.start()
            listening = true
            response = "Estou ouvindo, senhor."
            isProcessing = false
            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                        if result.isFinal && !self.isProcessing {
                            self.isProcessing = true
                            let command = self.transcript
                            self.stop()
                            await self.process(command)
                        }
                    }
                    if error != nil { self.stop() }
                }
            }
        } catch {
            stop()
            response = "Falha ao iniciar o microfone: \(error.localizedDescription)"
        }
    }

    func stop() {
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        listening = false
    }

    private func process(_ command: String) async {
        let lower = command.lowercased()
        if lower.contains("bom dia") { say("Bom dia, senhor. Sistemas prontos."); return }
        if lower.contains("que horas") {
            say("Agora são \(Date().formatted(date: .omitted, time: .shortened))."); return
        }
        if lower.contains("seu nome") { say("Sou o SAMURAY JARVIS, seu assistente pessoal."); return }
        guard let url = URL(string: serverURL), ["http", "https"].contains(url.scheme?.lowercased() ?? ""), !accessToken.isEmpty else {
            say("Comando recebido. Para controlar aparelhos ou conversar com uma IA online, configure um servidor autorizado em Ajustes.")
            return
        }
        do {
            var req = URLRequest(url: url.appendingPathComponent("api/voice-command"))
            req.httpMethod = "POST"
            req.timeoutInterval = 12
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(CommandRequest(command: command))
            let (data, reply) = try await URLSession.shared.data(for: req)
            guard let http = reply as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                say("O servidor não aceitou o comando. Confira a conexão e o token."); return
            }
            let result = try JSONDecoder().decode(CommandResponse.self, from: data)
            say(result.response)
        } catch { say("Não consegui acessar o servidor. Verifique o endereço e a rede.") }
    }

    func say(_ text: String) {
        response = text
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "pt-BR")
        utterance.rate = 0.48
        speaker.speak(utterance)
    }
}
private struct CommandRequest: Encodable { let command: String }
private struct CommandResponse: Decodable { let response: String }
