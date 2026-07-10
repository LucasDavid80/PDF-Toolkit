# PDF Toolkit

App desktop (Windows, macOS, Linux) em Flutter para:
1. Converter imagens (PNG, JPG, JPEG) em PDF.
2. Unir múltiplos PDFs em um único arquivo.

Repositório: https://github.com/LucasDavid80/PDF-Toolkit.git

## Documentação do projeto (Spec-Driven Development)

- [`docs/spec.md`](docs/spec.md) — especificação funcional
- [`docs/plan.md`](docs/plan.md) — plano técnico
- [`docs/tasks.md`](docs/tasks.md) — lista de tarefas
- [`AGENTS.md`](AGENTS.md) — regras de comportamento para agentes de IA que trabalham neste repositório (fluxo de git, convenções de commit, etc.)

## Arquitetura e Decisões Técnicas (Solução 3)

Originalmente, o projeto dependia do pacote `pdf_combiner`. No entanto, devido a restrições e bugs de CMake/compilação nativa de C++ no ecossistema Windows, a dependência foi substituída pela **Solução 3** para maior estabilidade:

1. **Conversão de Imagens → PDF**: Implementada utilizando `pdf` (geração de documentos) + `image` (decodificação de formatos de imagem). Ambos são escritos em **Dart puro**, o que elimina dependências nativas e simplifica a compilação cruzada em qualquer plataforma hospedeira.
2. **União de PDFs**: Implementada através de `pdf_manipulator`. Este pacote envolve um motor escrito em Rust de alta performance. Durante a compilação, o plugin baixa de forma transparente o binário pré-compilado nativo apropriado para a plataforma (como a `pdf_oxide.dll` no Windows), garantindo que o build funcione sem a necessidade de ferramentas de compilação locais do desenvolvedor ou da CI.

Essa stack estável assegura compatibilidade offline-first, performance nativa e builds limpos em Windows, macOS e Linux.

## Rodando localmente

```bash
cd pdf_toolkit
flutter pub get
flutter run -d windows   # ou macos / linux
```

---

## Empacotamento, Assinatura de Código e Release

Foram criados scripts automáticos para compilar, empacotar e realizar a assinatura (Code Signing) do aplicativo em cada plataforma.

### 1. Windows (Inno Setup & Signtool)
Gera um instalador executável `.exe` que instala o aplicativo, cria atalhos e permite desinstalação.
* **Pré-requisitos locais:**
  * Inno Setup 6 instalado no sistema (caminho padrão ou no PATH).
  * Windows SDK instalado (para acesso ao `signtool.exe` caso vá assinar localmente).
* **Como rodar localmente:**
  ```powershell
  # Apenas build e gerador de instalador (sem assinatura):
  powershell -File pdf_toolkit/windows/installer/build_installer.ps1

  # Build, gerador de instalador e assinatura de código:
  powershell -File pdf_toolkit/windows/installer/build_installer.ps1 -CertPath "C:\caminho\certificado.pfx" -CertPassword "sua_senha"
  ```

### 2. macOS (DMG & codesign/notarytool)
Gera uma imagem `.dmg` assinada e enviada para notarização da Apple.
* **Pré-requisitos locais:**
  * Xcode e utilitário `hdiutil` no PATH.
  * Certificado Developer ID no Keychain.
* **Como rodar localmente:**
  ```bash
  bash pdf_toolkit/macos/build_macos.sh
  ```

### 3. Linux (AppImage & appimagetool)
Gera um pacote autossuficiente `.AppImage`.
* **Pré-requisitos locais:**
  * FUSE instalado no sistema para permitir a execução do `appimagetool`.
* **Como rodar localmente:**
  ```bash
  bash pdf_toolkit/linux/build_linux.sh
  ```

---

## Secrets e Credenciais para CI/CD (GitHub Actions)

Para a automação no GitHub Actions (Fase 7), os seguintes segredos (Secrets) devem ser configurados nas configurações do repositório (`Settings > Secrets and variables > Actions`):

| Secret Name | Plataforma | Descrição |
|---|---|---|
| `WINDOWS_CERTIFICATE_BASE64` | Windows | O certificado `.pfx` ou `.p12` codificado em Base64. |
| `WINDOWS_CERTIFICATE_PASSWORD` | Windows | A senha para descriptografar o certificado PFX. |
| `MACOS_CERTIFICATE_BASE64` | macOS | O certificado Developer ID Application (`.p12`) codificado em Base64. |
| `MACOS_CERTIFICATE_PASSWORD` | macOS | A senha do certificado P12 do macOS. |
| `MACOS_NOTARIZATION_KEY` | macOS | Senha específica do app (App-Specific Password) ou API Key do App Store Connect para notarização via `notarytool`. |
| `MACOS_KEYCHAIN_PASSWORD` | macOS | Senha para criar um chaveiro temporário de build no runner do GitHub. |

> [!IMPORTANT]
> **Nunca** commite arquivos de certificado (.pfx, .p12, .pem) ou chaves privadas diretamente no repositório do Git. Use sempre variáveis de ambiente e segredos na CI/CD.
