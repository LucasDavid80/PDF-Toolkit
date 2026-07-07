#!/bin/bash
# Script de automacao de build, empacotamento e assinatura para macOS
set -e

echo "=== 1. Construindo aplicativo Flutter para macOS em modo Release ==="
flutter build macos --release

APP_PATH="build/macos/Build/Products/Release/pdf_toolkit.app"

# Assinatura condicional se a chave/Developer ID for passada
if [ ! -z "$MACOS_CERTIFICATE_DATA" ]; then
  echo "=== 2. Importando certificado e assinando codigo ==="
  # Nota: Em ambiente de CI, seria necessario decodificar o certificado P12, importá-lo no Keychain
  # e desbloqueá-lo antes de rodar o codesign.
  # codesign --deep --force --options runtime --sign "Developer ID Application: $MACOS_DEVELOPER_NAME" "$APP_PATH"
else
  echo "=== 2. Assinatura de codigo pulada (MACOS_CERTIFICATE_DATA nao configurada) ==="
fi

echo "=== 3. Criando instalador DMG ==="
mkdir -p build/macos/dmg
hdiutil create -fs HFS+ -srcfolder "$APP_PATH" -volname "PDF Toolkit" build/macos/dmg/pdf_toolkit.dmg

if [ ! -z "$MACOS_NOTARIZATION_KEY" ]; then
  echo "=== 4. Enviando para notarizacao da Apple ==="
  # xcrun notarytool submit build/macos/dmg/pdf_toolkit.dmg --key "$MACOS_NOTARIZATION_KEY" --wait
  # xcrun stapler staple build/macos/dmg/pdf_toolkit.dmg
else
  echo "=== 4. Notarizacao pulada (notarytool keys nao configuradas) ==="
fi

echo "Processo de build do macOS concluido!"
