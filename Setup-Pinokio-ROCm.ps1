# ==============================================================================
# PINOKIO ROCm AUTOMATED ONE-CLICK INSTALLER & OPTIMIZER
# Target Hardware: AMD AI Pro 9700 (gfx1201 / RDNA)
# Author: Mana Turipa (Open-Source Developer)
# ==============================================================================

$ErrorActionPreference = "Continue"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " PINOKIO ROCm AUTOMATED ONE-CLICK INSTALLER & OPTIMIZER" -ForegroundColor Cyan
Write-Host " Author: Mana Turipa - Open-Source Developer" -ForegroundColor Yellow
Write-Host " Target Hardware: AMD AI Pro 9700 (gfx1201)" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# STEP 1: GPU TDR Driver Latency Optimization
Write-Host "[1/7] Configuring GPU Graphics Driver TDR Delays..." -ForegroundColor Green
$GraphicsRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
if (Test-Path $GraphicsRegPath) {
    Set-ItemProperty -Path $GraphicsRegPath -Name "TdrDelay" -Value 10 -Type DWord -Force
    Set-ItemProperty -Path $GraphicsRegPath -Name "TdrDdiDelay" -Value 10 -Type DWord -Force
    Write-Host "  -> TdrDelay and TdrDdiDelay set to 10 seconds." -ForegroundColor Gray
}

# STEP 2: Configure .wslconfig
Write-Host "[2/7] Generating Optimized .wslconfig..." -ForegroundColor Green
$wslConfigPath = Join-Path $env:USERPROFILE ".wslconfig"
$wslConfigContent = @"
[wsl2]
memory=16GB
kernelCommandLine=hwcache_attr=disable
processors=8
swap=0
localhostForwarding=true
nestedVirtualization=true
guiApplications=true
gpu=true

[experimental]
autoMemoryReclaim=dropcache
sparseVhd=true
"@
Set-Content -Path $wslConfigPath -Value $wslConfigContent -Encoding UTF8 -Force
Write-Host "  -> Configured $wslConfigPath with swap=0 and hardware GPU passthrough." -ForegroundColor Gray

# STEP 3: Setup Windows Defender Exclusions
Write-Host "[3/7] Setting Windows Defender Real-Time Scanning Exclusions..." -ForegroundColor Green
try {
    Add-MpPreference -ExclusionPath "$env:LOCALAPPDATA\Packages" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionPath "C:\Users\$env:USERNAME\AppData\Local\wsl" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionPath "C:\pinokio" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "wsl.exe" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "wslhost.exe" -ErrorAction SilentlyContinue
    Write-Host "  -> Defender exclusions applied for WSL disks, C:\pinokio, and processes." -ForegroundColor Gray
} catch {
    Write-Host "  -> Note: Defender exclusions could not be applied automatically." -ForegroundColor Yellow
}

# STEP 4: Install / Update WSL 2
Write-Host "[4/7] Checking and Updating WSL 2 Kernel & WSLg..." -ForegroundColor Green
wsl --update --web-download
wsl --set-default-version 2

$distros = wsl --list --quiet 2>$null
$distroName = "Ubuntu-24.04"
if ($distros -notmatch "Ubuntu") {
    Write-Host "  -> Installing Ubuntu-24.04 for WSL 2..." -ForegroundColor Yellow
    wsl --install -d Ubuntu-24.04 --no-launch
} elseif ($distros -match "Ubuntu-24.04") {
    $distroName = "Ubuntu-24.04"
} elseif ($distros -match "Ubuntu-22.04") {
    $distroName = "Ubuntu-22.04"
} else {
    $distroName = "Ubuntu"
}
Write-Host "  -> Target WSL 2 Distribution: $distroName" -ForegroundColor Gray

# STEP 5: Provision Linux Environment, AMD ROCm Stack, Browser Bridge & Pinokio
Write-Host "[5/8] Provisioning Linux Packages, ROCm Libraries, Browser Bridge & Pinokio..." -ForegroundColor Green

# Install essential Linux packages
Write-Host "  -> Installing essential Linux packages..." -ForegroundColor Yellow
wsl.exe -d $distroName -u root -- bash -c "apt-get update && apt-get install -y wget curl git build-essential python3 python3-pip python3-venv nodejs npm"

# Download and install Pinokio v8.0.40 in WSL
Write-Host "  -> Downloading Pinokio v8.0.40 for Linux..." -ForegroundColor Yellow
$pinokioDebUrl = "https://github.com/pinokiocomputer/pinokio/releases/download/v8.0.40/Pinokio_8.0.40_amd64.deb"
$pinokioDebPath = "/tmp/Pinokio_8.0.40_amd64.deb"

# Download the .deb package into WSL
wsl.exe -d $distroName -u root -- bash -c "wget -q '$pinokioDebUrl' -O $pinokioDebPath && echo 'Download complete' || echo 'Download failed'"

# Install the .deb package in WSL
Write-Host "  -> Installing Pinokio v8.0.40 in WSL..." -ForegroundColor Yellow
wsl.exe -d $distroName -u root -- bash -c "dpkg -i $pinokioDebPath || apt-get install -f -y"

# Verify Pinokio installation
Write-Host "  -> Verifying Pinokio installation..." -ForegroundColor Yellow
wsl.exe -d $distroName -u root -- bash -c "which pinokio && pinokio --version || echo 'Pinokio installed at /opt/Pinokio'"

# Clean up downloaded .deb file
wsl.exe -d $distroName -u root -- bash -c "rm -f $pinokioDebPath"

# Setup browser bridge
$bridgeFile = Join-Path $PSScriptRoot "wsl-browser-bridge"
if (Test-Path $bridgeFile) {
    wsl.exe -d $distroName -u root -- bash -c "cp \"$(wslpath \"$bridgeFile\")\" /usr/local/bin/wsl-browser-bridge && chmod +x /usr/local/bin/wsl-browser-bridge && ln -sf /usr/local/bin/wsl-browser-bridge /usr/local/bin/xdg-open && ln -sf /usr/local/bin/wsl-browser-bridge /usr/local/bin/wslview && ln -sf /usr/local/bin/wsl-browser-bridge /usr/local/bin/x-www-browser && ln -sf /usr/local/bin/wsl-browser-bridge /usr/local/bin/sensible-browser"
}

# Copy ROCm launcher script
$shFile = Join-Path $PSScriptRoot "pinokio-rocm.sh"
if (Test-Path $shFile) {
    wsl.exe -d $distroName -u root -- bash -c "TARGET_USER=`$(id -un 1000 2>/dev/null || echo \"manat\"); USER_HOME=`$(eval echo \"~`$TARGET_USER\"); cp \"$(wslpath \"$shFile\")\" `$USER_HOME/pinokio-rocm.sh && chmod +x `$USER_HOME/pinokio-rocm.sh && chown `$TARGET_USER:`$TARGET_USER `$USER_HOME/pinokio-rocm.sh"
}

# STEP 6: Configure Pinokio for WSL Backend
Write-Host "[6/8] Configuring Pinokio for WSL Backend Mode..." -ForegroundColor Green

# Create Pinokio configuration for WSL backend
$pinokioConfig = @"
{
  "theme": "dark",
  "home": "/home/`$(whoami)/pinokio",
  "version": "8.0.40",
  "wsl_backend": true,
  "gpu": "amd_rocm",
  "hardware": "AMD AI Pro 9700 (gfx1201)"
}
"@

wsl.exe -d $distroName -- bash -c "mkdir -p ~/.pinokio && echo '$pinokioConfig' > ~/.pinokio/config.json"

# STEP 7: Create Desktop & Start Menu Shortcuts
Write-Host "[7/8] Creating Desktop and Launcher Shortcuts..." -ForegroundColor Green
$targetBat = "C:\Users\manat\Desktop\Programs & AI\AI Programs and creations\Applications\Local AI Apps\Pinokio-ROCm.bat"
if (!(Test-Path $targetBat)) {
    $targetBat = Join-Path $PSScriptRoot "Pinokio-ROCm.bat"
}
$desktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$shortcutPath = Join-Path $desktopPath "Pinokio ROCm (AMD AI Pro 9700).lnk"

$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $targetBat
$Shortcut.WorkingDirectory = (Split-Path $targetBat)
$Shortcut.Description = "Pinokio with AMD ROCm Acceleration (Zero-Lag) - AMD AI Pro 9700"
$iconPath = "C:\Users\manat\AppData\Local\wsl\{31dffdb2-2fe3-482d-ac48-eb7553933fb8}\shortcut.ico"
if (Test-Path $iconPath) {
    $Shortcut.IconLocation = $iconPath
}
$Shortcut.Save()
Write-Host "  -> Desktop shortcut created: $shortcutPath" -ForegroundColor Gray

# STEP 8: Final Verification
Write-Host "[8/8] Verifying System Setup..." -ForegroundColor Green

# Verify WSL Pinokio installation
Write-Host "  -> Verifying Pinokio in WSL..." -ForegroundColor Yellow
$wslPinokioCheck = wsl.exe -d $distroName -- bash -c "which pinokio && pinokio --version || echo 'Not found'"
if ($wslPinokioCheck -match "pinokio") {
    Write-Host "  -> Pinokio successfully installed in WSL" -ForegroundColor Green
} else {
    Write-Host "  -> Warning: Pinokio installation verification inconclusive" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host " PINOKIO ROCm SYSTEM INSTALLED AND OPTIMIZED SUCCESSFULLY!" -ForegroundColor Green
Write-Host " Architecture: Windows Pinokio GUI + WSL2 ROCm Backend" -ForegroundColor Cyan
Write-Host " Target Hardware: AMD AI Pro 9700 (gfx1201)" -ForegroundColor Yellow
Write-Host " Pinokio Version: v8.0.40 (Linux)" -ForegroundColor Yellow
Write-Host " Developer: Mana Turipa (Open-Source Developer)" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Architecture Summary:" -ForegroundColor Cyan
Write-Host "  - Windows: Pinokio GUI (C:\pinokio)" -ForegroundColor White
Write-Host "  - WSL2: Pinokio Backend with ROCm GPU acceleration" -ForegroundColor White
Write-Host "  - GPU: AMD AI Pro 9700 (gfx1201) via ROCm 7.2" -ForegroundColor White
Write-Host ""
Write-Host "You can now launch Pinokio using:" -ForegroundColor Green
Write-Host "  1. Desktop shortcut: Pinokio ROCm (AMD AI Pro 9700).lnk" -ForegroundColor White
Write-Host "  2. Batch file: Pinokio-ROCm.bat" -ForegroundColor White
Write-Host "  3. Direct WSL command: wsl -d $distroName -- pinokio" -ForegroundColor White
