# ==============================================================================
# PINOKIO ROCm AUTOMATED ONE-CLICK INSTALLER & OPTIMIZER
# Multi-architecture support: AMD RDNA2 (gfx103x), RDNA3 (gfx110x), RDNA4 (gfx120x)
# Author: Mana Turipa (Open-Source Developer)
# ==============================================================================

$ErrorActionPreference = "Continue"

# ----------------------------------------------------------------------------
# GPU DETECTION: map the installed AMD GPU to an RDNA generation + gfx target.
# ----------------------------------------------------------------------------
function Get-AmdGpuInfo {
    $gpu = Get-CimInstance Win32_VideoController |
        Where-Object { $_.Name -match 'AMD|Radeon|ATI' } |
        Select-Object -First 1

    if (-not $gpu) {
        return @{ Name = "Unknown"; Gen = "RDNA3"; Gfx = "11.0.0"; Family = "consumer" }
    }

    $name = $gpu.Name
    $family = if ($name -match 'Pro|AI PRO|Instinct|FirePro') { "pro" } else { "consumer" }

    if ($name -match '9700|9070|9060|RX\s*90') {
        return @{ Name = $name; Gen = "RDNA4"; Gfx = "12.0.1"; Family = $family }
    }
    elseif ($name -match '7900|7800|7700|7600|RX\s*7') {
        return @{ Name = $name; Gen = "RDNA3"; Gfx = "11.0.0"; Family = $family }
    }
    elseif ($name -match '6900|6800|6700|6600|6500|RX\s*6') {
        return @{ Name = $name; Gen = "RDNA2"; Gfx = "10.3.0"; Family = $family }
    }
    return @{ Name = $name; Gen = "RDNA3"; Gfx = "11.0.0"; Family = $family }
}

$gpu = Get-AmdGpuInfo

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " PINOKIO ROCm AUTOMATED ONE-CLICK INSTALLER & OPTIMIZER" -ForegroundColor Cyan
Write-Host " Author: Mana Turipa - Open-Source Developer" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host (" Detected GPU  : " + $gpu.Name) -ForegroundColor Green
Write-Host (" Architecture  : " + $gpu.Gen + "  (gfx target " + $gpu.Gfx + ")") -ForegroundColor Green
Write-Host ""

# STEP 1: GPU TDR Driver Latency Optimization
Write-Host "[1/8] Configuring GPU Graphics Driver TDR Delays..." -ForegroundColor Green
$GraphicsRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
if (Test-Path $GraphicsRegPath) {
    Set-ItemProperty -Path $GraphicsRegPath -Name "TdrDelay" -Value 10 -Type DWord -Force
    Set-ItemProperty -Path $GraphicsRegPath -Name "TdrDdiDelay" -Value 10 -Type DWord -Force
    Write-Host "  -> TdrDelay and TdrDdiDelay set to 10 seconds." -ForegroundColor Gray
}

# STEP 2: Configure .wslconfig
Write-Host "[2/8] Generating Optimized .wslconfig..." -ForegroundColor Green
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
Write-Host "[3/8] Setting Windows Defender Real-Time Scanning Exclusions..." -ForegroundColor Green
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
Write-Host "[4/8] Checking and Updating WSL 2 Kernel & WSLg..." -ForegroundColor Green
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

# STEP 5: Provision Linux Environment, per-arch ROCm stack, Browser Bridge & Pinokio
Write-Host "[5/8] Provisioning Linux Packages, ROCm Libraries, Browser Bridge & Pinokio..." -ForegroundColor Green

$bridgeFile = Join-Path $PSScriptRoot "wsl-browser-bridge"
if (Test-Path $bridgeFile) {
    wsl.exe -d $distroName -u root -- bash -c "cp \"$(wslpath \"$bridgeFile\")\" /usr/local/bin/wsl-browser-bridge && chmod +x /usr/local/bin/wsl-browser-bridge && ln -sf /usr/local/bin/wsl-browser-bridge /usr/local/bin/xdg-open && ln -sf /usr/local/bin/wsl-browser-bridge /usr/local/bin/wslview && ln -sf /usr/local/bin/wsl-browser-bridge /usr/local/bin/x-www-browser && ln -sf /usr/local/bin/wsl-browser-bridge /usr/local/bin/sensible-browser"
}

$shFile = Join-Path $PSScriptRoot "pinokio-rocm.sh"
if (Test-Path $shFile) {
    wsl.exe -d $distroName -u root -- bash -c "TARGET_USER=`$(id -un 1000 2>/dev/null || echo \"manat\"); USER_HOME=`$(eval echo \"~`$TARGET_USER\"); cp \"$(wslpath \"$shFile\")\" `$USER_HOME/pinokio-rocm.sh && chmod +x `$USER_HOME/pinokio-rocm.sh && chown `$TARGET_USER:`$TARGET_USER `$USER_HOME/pinokio-rocm.sh"
}

# Pass the detected architecture into the WSL environment (per-arch HSA override).
$gfxOverride = $gpu.Gfx
wsl.exe -d $distroName -u root -- bash -c "GFX_OVERRIDE=$gfxOverride bash -c 'grep -q HSA_OVERRIDE_GFX_VERSION /home/manat/.bashrc 2>/dev/null || echo \"export HSA_OVERRIDE_GFX_VERSION=$gfxOverride\" >> /home/manat/.bashrc'"

# STEP 6: Open the correct AMD driver download page for the detected GPU.
Write-Host "[6/8] Opening AMD driver download for detected GPU..." -ForegroundColor Green
$driverUrl = "https://www.amd.com/en/support/download/drivers.html"
if ($gpu.Family -eq "pro") {
    $driverUrl = "https://www.amd.com/en/support/download/drivers.html"
}
Write-Host "  -> Opening $driverUrl in your browser." -ForegroundColor Gray
try { Start-Process $driverUrl } catch {}

# STEP 7: Create Desktop & Start Menu Shortcuts
Write-Host "[7/8] Creating Desktop and Launcher Shortcuts..." -ForegroundColor Green
$targetBat = "C:\Users\manat\Desktop\Programs & AI\AI Programs and creations\Applications\Local AI Apps\Pinokio-ROCm.bat"
if (!(Test-Path $targetBat)) {
    $targetBat = Join-Path $PSScriptRoot "Pinokio-ROCm.bat"
}
$desktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$shortcutPath = Join-Path $desktopPath ("Pinokio ROCm (" + $gpu.Gen + ").lnk")

$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $targetBat
$Shortcut.WorkingDirectory = (Split-Path $targetBat)
$Shortcut.Description = "Pinokio with AMD ROCm Acceleration - " + $gpu.Name
$iconPath = "C:\Users\manat\AppData\Local\wsl\{31dffdb2-2fe3-482d-ac48-eb7553933fb8}\shortcut.ico"
if (Test-Path $iconPath) {
    $Shortcut.IconLocation = $iconPath
}
$Shortcut.Save()
Write-Host "  -> Desktop shortcut created: $shortcutPath" -ForegroundColor Gray

# STEP 8: Final Verification
Write-Host "[8/8] Verifying System Setup..." -ForegroundColor Green
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host " PINOKIO ROCm SYSTEM INSTALLED AND OPTIMIZED SUCCESSFULLY!" -ForegroundColor Green
Write-Host (" GPU: " + $gpu.Name + "  (" + $gpu.Gen + ", gfx " + $gpu.Gfx + ")") -ForegroundColor Yellow
Write-Host " Developer: Mana Turipa (Open-Source Developer)" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Green
Write-Host "You can now launch Pinokio using the desktop shortcut or Pinokio-ROCm.bat."
