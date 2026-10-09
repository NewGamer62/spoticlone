# ==============================================================================
# SpotiClone - Automated Setup & Environment Checker
# Checks Flutter, Android, and Windows C++ build tools, installs prerequisites.
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "         SpotiClone - Assistant de Configuration          " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""

# 1. Vérification de Flutter
Write-Host "[1/4] Vérification du SDK Flutter..." -ForegroundColor Cyan
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    Write-Host "❌ Flutter n'est pas détecté dans votre PATH." -ForegroundColor Red
    Write-Host "Installez Flutter depuis https://flutter.dev avant de continuer." -ForegroundColor Yellow
    exit 1
}
$flutterVersion = & flutter --version | Select-Object -First 1
Write-Host "  ✔ Détecté : $flutterVersion" -ForegroundColor Green

# 2. Vérification des outils de build Windows C++
Write-Host ""
Write-Host "[2/4] Vérification des Build Tools C++ pour Windows..." -ForegroundColor Cyan

$vsWherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$hasCppTools = $false

if (Test-Path $vsWherePath) {
    $vsInstance = & $vsWherePath -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($vsInstance) {
        $hasCppTools = $true
        Write-Host "  ✔ Outils C++ Visual Studio détectés : $vsInstance" -ForegroundColor Green
    }
}

if (-not $hasCppTools) {
    Write-Host "  ⚠ Les outils C++ pour Windows (Desktop development with C++) ne sont pas installés." -ForegroundColor Yellow
    Write-Host "    Pour compiler SpotiClone nativement sous Windows, ce composant est requis." -ForegroundColor Yellow
    Write-Host ""
    $installNow = Read-Host "Souhaitez-vous installer les Build Tools Visual Studio C++ via winget maintenant ? (O/N)"
    if ($installNow -match "^[oOyY]") {
        Write-Host "Lancement de l'installation des Build Tools C++ via winget..." -ForegroundColor Cyan
        & winget install --id Microsoft.VisualStudio.2022.BuildTools --override "--passive --add Microsoft.VisualStudio.Workload.VCTools"
        Write-Host "✔ Installation terminée ! Veuillez redémarrer ce terminal après le build si nécessaire." -ForegroundColor Green
    } else {
        Write-Host "  Ignoré. Vous pourrez toujours compiler pour Android." -ForegroundColor Gray
    }
}

# 3. Récupération des dépendances Flutter
Write-Host ""
Write-Host "[3/4] Récupération des dépendances Flutter (flutter pub get)..." -ForegroundColor Cyan
& flutter pub get
Write-Host "  ✔ Dépendances à jour." -ForegroundColor Green

# 4. Choix de lancement
Write-Host ""
Write-Host "[4/4] Prêt à lancer l'application !" -ForegroundColor Cyan
Write-Host "1. Lancer sous Windows Desktop (C++ Natif)" -ForegroundColor White
Write-Host "2. Lancer sous Android (Smartphone USB ou Émulateur)" -ForegroundColor White
Write-Host "3. Exécuter les tests automatisés (flutter test)" -ForegroundColor White
Write-Host "4. Quitter" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Votre choix (1/2/3/4)"
switch ($choice) {
    "1" {
        Write-Host "Démarrage de SpotiClone sur Windows..." -ForegroundColor Green
        & flutter run -d windows
    }
    "2" {
        Write-Host "Démarrage de SpotiClone sur Android..." -ForegroundColor Green
        & flutter run -d android
    }
    "3" {
        Write-Host "Exécution de la suite de tests..." -ForegroundColor Green
        & flutter test
    }
    default {
        Write-Host "Configuration terminée avec succès." -ForegroundColor Green
    }
}
