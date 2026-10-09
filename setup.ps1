# ==============================================================================
# SpotiClone - Automated Setup & Environment Checker
# Checks Flutter, Android, and Windows C++ build tools, installs prerequisites.
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "         SpotiClone - Assistant de Configuration          " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""

# 1. Verification de Flutter
Write-Host "[1/4] Verification du SDK Flutter..." -ForegroundColor Cyan
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    Write-Host "[X] Flutter n'est pas detecte dans votre PATH." -ForegroundColor Red
    Write-Host "Installez Flutter depuis https://flutter.dev avant de continuer." -ForegroundColor Yellow
    exit 1
}
$flutterVersion = & flutter --version | Select-Object -First 1
Write-Host "  [OK] Detecte : $flutterVersion" -ForegroundColor Green

# 2. Verification du Mode Developpeur Windows et des outils C++
Write-Host ""
Write-Host "[2/4] Verification du Mode Developpeur Windows et des outils C++..." -ForegroundColor Cyan

# Detection du Mode Developpeur (requis pour les symlinks des plugins)
$devMode = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
if ($devMode -ne 1) {
    Write-Host "  [!] Le Mode Developpeur Windows n'est pas active." -ForegroundColor Yellow
    Write-Host "      Flutter en a besoin pour creer les liens symboliques des plugins natifs." -ForegroundColor Yellow
    $openSettings = Read-Host "Souhaitez-vous ouvrir les parametres Windows pour l'activer ? (O/N)"
    if ($openSettings -match "^[oOyY]") {
        Start-Process "ms-settings:developers"
        Write-Host "  [INFO] Activez l'interrupteur 'Mode Developpeur', puis revenez ici." -ForegroundColor Cyan
        Read-Host "Appuyez sur Entree une fois le mode active..."
    }
} else {
    Write-Host "  [OK] Mode Developpeur Windows actif." -ForegroundColor Green
}

$progFilesX86 = [System.Environment]::GetFolderPath('ProgramFilesX86')
$vsWherePath = "$progFilesX86\Microsoft Visual Studio\Installer\vswhere.exe"
$hasCppTools = $false

if (Test-Path -Path $vsWherePath) {
    $vsInstance = & $vsWherePath -latest -products "*" -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($vsInstance) {
        $hasCppTools = $true
        Write-Host "  [OK] Outils C++ Visual Studio detectes : $vsInstance" -ForegroundColor Green
    }
}

if (-not $hasCppTools) {
    Write-Host "  [!] Les outils C++ pour Windows (Desktop development with C++) ne sont pas installes." -ForegroundColor Yellow
    Write-Host "      Pour compiler SpotiClone nativement sous Windows, ce composant est requis." -ForegroundColor Yellow
    Write-Host ""
    $installNow = Read-Host "Souhaitez-vous installer les Build Tools Visual Studio C++ via winget maintenant ? (O/N)"
    if ($installNow -match "^[oOyY]") {
        Write-Host "Lancement de l'installation des Build Tools C++ via winget..." -ForegroundColor Cyan
        & winget install --id Microsoft.VisualStudio.2022.BuildTools --override "--passive --add Microsoft.VisualStudio.Workload.VCTools"
        Write-Host "  [OK] Installation terminee ! Veuillez redemarrer ce terminal apres le build si necessaire." -ForegroundColor Green
    } else {
        Write-Host "  [INFO] Ignore. Vous pourrez toujours compiler pour Android." -ForegroundColor Gray
    }
}

# 3. Recuperation des dependances Flutter
Write-Host ""
Write-Host "[3/4] Recuperation des dependances Flutter (flutter pub get)..." -ForegroundColor Cyan
& flutter pub get
Write-Host "  [OK] Dependances a jour." -ForegroundColor Green

# 4. Choix de lancement
Write-Host ""
Write-Host "[4/4] Pret a lancer l'application !" -ForegroundColor Cyan
Write-Host "1. Lancer sous Windows Desktop (C++ Natif)" -ForegroundColor White
Write-Host "2. Lancer sous Android (Smartphone USB ou Emulateur)" -ForegroundColor White
Write-Host "3. Executer les tests automatises (flutter test)" -ForegroundColor White
Write-Host "4. Quitter" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Votre choix (1/2/3/4)"
switch ($choice) {
    "1" {
        Write-Host "Demarrage de SpotiClone sur Windows..." -ForegroundColor Green
        & flutter run -d windows
    }
    "2" {
        Write-Host "Demarrage de SpotiClone sur Android..." -ForegroundColor Green
        & flutter run -d android
    }
    "3" {
        Write-Host "Execution de la suite de tests..." -ForegroundColor Green
        & flutter test
    }
    default {
        Write-Host "Configuration terminee avec succes." -ForegroundColor Green
    }
}
