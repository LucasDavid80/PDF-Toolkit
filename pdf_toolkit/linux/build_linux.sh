#!/bin/bash
# Script de automacao de build, empacotamento e geracao de AppImage para Linux
set -e

echo "=== 1. Construindo aplicativo Flutter para Linux em modo Release ==="
flutter build linux --release

BUILD_PATH="build/linux/x64/release/bundle"
APPDIR="build/linux/AppDir"

mkdir -p "$APPDIR"
cp -r "$BUILD_PATH"/* "$APPDIR"/

# Criar arquivo desktop para especificacao do AppImage
cat <<EOF > "$APPDIR"/pdf_toolkit.desktop
[Desktop Entry]
Name=PDF Toolkit
Comment=Conversor e Combinador de PDFs
Exec=pdf_toolkit
Icon=pdf_toolkit
Type=Application
Categories=Office;Utility;
EOF

# Copiar icone
cp windows/runner/resources/app_icon.ico "$APPDIR"/pdf_toolkit.ico

# Criar AppRun basico
cat <<EOF > "$APPDIR"/AppRun
#!/bin/sh
SELF=\$(readlink -f "\$0")
HERE=\$(dirname "\$SELF")
exec "\$HERE/pdf_toolkit" "\$@"
EOF
chmod +x "$APPDIR"/AppRun

echo "=== 2. Baixando e executando appimagetool ==="
if [ ! -f "build/linux/appimagetool" ]; then
  mkdir -p build/linux
  curl -Lo build/linux/appimagetool https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage
  chmod +x build/linux/appimagetool
fi

# Executar geracao do AppImage
ARCH=x86_64 build/linux/appimagetool "$APPDIR" build/linux/pdf_toolkit.AppImage || echo "Geracao de AppImage local falhou. (Geralmente exige FUSE instalado no host)"

echo "Processo de build do Linux concluido!"
