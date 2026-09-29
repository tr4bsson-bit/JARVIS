# SAMURAY JARVIS X — iPhone (projeto nativo)

Este pacote contém código SwiftUI para iOS 17+. Não é um IPA compilado nem assinado.

## Como gerar IPA
1. Em um Mac, instale Xcode e XcodeGen (`brew install xcodegen`).
2. Na pasta do projeto, execute `xcodegen generate` e abra `SamurayJarvis.xcodeproj`.
3. Em Signing & Capabilities, escolha sua equipe Apple e um Bundle Identifier exclusivo.
4. Conecte o iPhone e pressione Run para instalar diretamente. Para exportar IPA, use Product > Archive > Distribute App e escolha a distribuição permitida pela sua conta.

## Funcionalidades desta versão
- Interface nativa SwiftUI, microfone e reconhecimento de fala pt-BR quando o iOS disponibilizar.
- Respostas faladas pt-BR pela voz do sistema (não é a voz original do filme nem necessariamente britânica).
- Comandos locais: bom dia, que horas são, seu nome.
- Estrutura para API opcional: POST /api/voice-command, JSON {"command":"..."}, resposta {"response":"..."}, token Bearer.

## Limitações
- Não há escuta contínua em segundo plano ou com iPhone bloqueado; integração com Siri/Atalhos ainda não implementada.
- O servidor Windows v0.4 não implementa necessariamente a rota /api/voice-command; precisa de um adaptador antes da integração.
- Sem Home Assistant ou adaptadores específicos, não controla TVs, PS4, câmeras ou roteador.
- O token preenchido no app não é persistido nesta versão; futuramente usar Keychain.
- Requer compilação e testes no Xcode, indisponível neste ambiente Linux.
