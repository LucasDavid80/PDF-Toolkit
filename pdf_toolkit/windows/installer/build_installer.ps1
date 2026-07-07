# Script de automação de build, empacotamento e assinatura para Windows

Param(
    [string]$CertPath = "",
    [string]$CertPassword = "",
    [string]$TimestampServer = "http://timestamp.digicert.com"
)

$ErrorActionPreference = "Stop"

Write-Host "=== 1. Construindo aplicativo Flutter em modo Release ===" -ForegroundColor Green
flutter build windows --release

Write-Host "=== 2. Localizando Inno Setup (ISCC.exe) ===" -ForegroundColor Green
$IsccPaths = @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe",
    "ISCC.exe" # se estiver no PATH
)
$IsccPath = $null
foreach ($path in $IsccPaths) {
    if (Get-Command $path -ErrorAction SilentlyContinue) {
        $IsccPath = $path
        break
    }
}

if ($null -eq $IsccPath) {
    Write-Warning "Inno Setup (ISCC.exe) nao foi localizado. O instalador (.exe) nao pode ser gerado localmente."
    Write-Warning "Certifique-se de instalar o Inno Setup 6 (https://jrsoftware.org/isdl.php)."
} else {
    Write-Host "ISCC localizado em: $IsccPath" -ForegroundColor Cyan
    Write-Host "Compilando instalador com Inno Setup..." -ForegroundColor Green
    & $IsccPath windows/installer/installer.iss
    Write-Host "Instalador gerado com sucesso em build/windows/installer/pdf_toolkit_installer.exe!" -ForegroundColor Green

    # Assinatura de código se o certificado for fornecido
    if ($CertPath -ne "" -and (Test-Path $CertPath)) {
        Write-Host "=== 3. Assinando o instalador gerado com Signtool ===" -ForegroundColor Green
        
        # Localiza signtool nos caminhos padrao do Windows SDK
        $SigntoolPaths = Get-ChildItem -Path "C:\Program Files (x86)\Windows Kits\10\bin" -Filter "signtool.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
        $SigntoolPath = $null
        if ($SigntoolPaths.Count -gt 0) {
            $SigntoolPath = $SigntoolPaths[0]
        } elseif (Get-Command "signtool.exe" -ErrorAction SilentlyContinue) {
            $SigntoolPath = "signtool.exe"
        }

        if ($null -eq $SigntoolPath) {
            Write-Warning "signtool.exe nao foi localizado nos caminhos do Windows SDK. A assinatura foi pulada."
        } else {
            Write-Host "Signtool localizado em: $SigntoolPath" -ForegroundColor Cyan
            Write-Host "Assinando executavel..." -ForegroundColor Green
            & $SigntoolPath sign /f $CertPath /p $CertPassword /fd sha256 /tr $TimestampServer /td sha256 build/windows/installer/pdf_toolkit_installer.exe
            Write-Host "Instalador assinado com sucesso!" -ForegroundColor Green
        }
    } else {
        Write-Host "=== 3. Assinatura de codigo pulada (nenhum certificado PFX fornecido) ===" -ForegroundColor Yellow
    }
}
