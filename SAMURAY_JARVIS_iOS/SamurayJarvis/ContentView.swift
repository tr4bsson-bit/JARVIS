import SwiftUI

struct ContentView: View {
    @StateObject private var voice = VoiceManager()
    @State private var showSettings = false
    var body: some View {
        ZStack {
            Color(red: 0.025, green: 0.06, blue: 0.12).ignoresSafeArea()
            VStack(spacing: 25) {
                HStack {
                    Text("SAMURAY JARVIS X").font(.headline).tracking(3)
                    Spacer()
                    Button { showSettings = true } label: { Image(systemName: "gearshape.fill") }
                }.foregroundStyle(.cyan)
                Spacer()
                ZStack {
                    Circle().stroke(.cyan.opacity(0.18), lineWidth: 20).frame(width: 245, height: 245)
                    Circle().stroke(.cyan.opacity(0.5), lineWidth: 2).frame(width: 204, height: 204)
                    Circle().stroke(.cyan, lineWidth: 6).frame(width: 165, height: 165)
                    Image(systemName: voice.listening ? "waveform" : "brain.head.profile")
                        .font(.system(size: 64)).foregroundStyle(.cyan)
                }.shadow(color: .cyan.opacity(0.45), radius: 28)
                Text(voice.listening ? "OUVINDO" : "PRONTO PARA COMANDOS")
                    .font(.caption.bold()).tracking(3).foregroundStyle(.cyan)
                Text(voice.transcript).font(.title3).multilineTextAlignment(.center).foregroundStyle(.white)
                    .frame(minHeight: 50)
                Text(voice.response).font(.body).multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8)).frame(minHeight: 85)
                Button { voice.toggle() } label: {
                    Label(voice.listening ? "PARAR" : "FALAR COM JARVIS", systemImage: voice.listening ? "stop.circle" : "mic.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding(18)
                }.buttonStyle(.borderedProminent).tint(.cyan).foregroundStyle(.black)
                Text("A escuta funciona com o aplicativo aberto. Para ativação com tela bloqueada, use Siri e Atalhos.")
                    .font(.caption).foregroundStyle(.gray).multilineTextAlignment(.center)
                Spacer()
            }.padding(24)
        }.sheet(isPresented: $showSettings) {
            NavigationStack {
                Form {
                    Section("Servidor opcional") {
                        TextField("https://seu-servidor.example", text: $voice.serverURL)
                            .textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled()
                        SecureField("Token de acesso", text: $voice.accessToken)
                    }
                    Section { Text("Sem servidor, os comandos locais de demonstração funcionam. Para controlar TVs e outros aparelhos, será necessária uma API compatível e autenticação.") }
                }.navigationTitle("Ajustes").toolbar { Button("Fechar") { showSettings = false } }
            }
        }
    }
}
