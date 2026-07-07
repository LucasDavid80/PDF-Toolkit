# Packaging and Code Signing (Windows, macOS, Linux)

Este documento explica onde colocar certificados e secrets necessários para gerar instaladores assinados por plataforma. NÃO commitar certificados ou chaves no repositório.

## Windows (Inno Setup + signtool)
- Arquivos esperados:
  - Certificado PFX (por exemplo `certs/windows/code_signing.pfx`)
  - Senha do PFX: via variável de ambiente `WINDOWS_CERT_PASSWORD`
- Variáveis/paths usadas pelo script `windows/installer/build_installer.ps1`:
  - Parâmetros do script: `-CertPath <caminho.pfx> -CertPassword <senha>`
  - No CI, configure um secret `WINDOWS_CERT_PFX` (base64) e `WINDOWS_CERT_PASSWORD`, desenpacote o PFX em tempo de execução num arquivo temporário e passe o caminho ao script.
- Observações:
  - O Inno Setup `ISCC.exe` deve estar instalado na máquina que gera o instalador.
  - `signtool.exe` vem com o Windows SDK; o script procura no PATH padrão.

## macOS (codesign + notarytool)
- Arquivos/segredos esperados:
  - `MACOS_CERTIFICATE_DATA`: certificado (.p12) codificado em base64 ou instalado no Keychain do runner.
  - `MACOS_DEVELOPER_NAME`: nome da identidade (ex.: "Developer ID Application: ACME Inc.").
  - `MACOS_NOTARIZATION_KEY`: credenciais para `notarytool` (quando aplicável).
- Script: `macos/build_macos.sh` já contém passos condicionais; o CI deve:
  1. Decodificar/importar o certificado no Keychain (senha em secret).
  2. Rodar `codesign` com a identidade apropriada.
  3. Rodar `xcrun notarytool submit` e `xcrun stapler staple` se `MACOS_NOTARIZATION_KEY` estiver presente.

## Linux (AppImage)
- Ferramentas necessárias: `appimagetool` (o script baixa automaticamente se não presente).
- Assinatura (opcional): GPG pode ser usada para assinar o AppImage — não obrigatório.
- Não há padrão universal de assinatura; documentar em `README` do release se necessário.

## Boas práticas para CI
- Nunca armazene PFX/keys diretamente no repositório. Use secrets do provedor de CI (GitHub Actions secrets).
- Crie jobs condicionais: execute etapas de assinatura/notarização somente se os secrets necessários estiverem presentes.
- Exemplo (GitHub Actions):
  - `WINDOWS_CERT_PFX` (base64), `WINDOWS_CERT_PASSWORD`
  - `MACOS_CERTIFICATE_DATA` (base64), `MACOS_DEVELOPER_NAME`, `MACOS_NOTARIZATION_KEY`

## Onde colocar os arquivos localmente (opcional)
- Recomenda-se uma pasta local `.secrets/` adicionada ao `.gitignore` contendo:
  - `.secrets/windows/code_signing.pfx`
  - `.secrets/macos/cert.p12`

## Exemplo de uso (local)
- Windows PowerShell:
  .\windows\installer\build_installer.ps1 -CertPath ".\\.secrets\\windows\\code_signing.pfx" -CertPassword "<senha>"

- macOS:
  export MACOS_CERTIFICATE_DATA=<base64-p12>
  export MACOS_DEVELOPER_NAME="Developer ID Application: Your Name"
  ./macos/build_macos.sh

---

Mantenha este documento atualizado sempre que houver mudanças no fluxo de empacotamento ou nas variáveis/paths esperados.
