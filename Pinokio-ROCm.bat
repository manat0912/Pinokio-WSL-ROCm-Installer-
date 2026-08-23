@echo off
title Pinokio ROCm - AMD AI Pro 9700 Launcher (Zero-Lag)
setlocal EnableDelayedExpansion

echo ====================================================================
echo        Pinokio ROCm High-Performance Launcher (Zero-Lag)
echo             Optimized for AMD AI Pro 9700 (gfx1201)
echo               Developer: Mana Turipa (Open Source)
echo ====================================================================
echo.
echo Architecture: Windows Pinokio GUI + WSL2 ROCm Backend
echo.

:: 1. Verify WSL Status
wsl -d Ubuntu-24.04 --status >nul 2>&1
if %ERRORLEVEL% neq 0 (
    wsl --status >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] WSL 2 is not currently running.
        echo Please ensure WSL is installed and enabled.
        pause
        exit /b 1
    )
)

:: 2. Export ROCm and Electron performance environment variables into WSL
set "WSLENV=ROCM_USE_WSL/u:HSA_OVERRIDE_GFX_VERSION/u:HSA_ENABLE_DXG_DETECTION/u:TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL/u:HSA_ENABLE_SDMA/u:HSA_FORCE_FINE_GRAIN_PCIE/u:GPU_MAX_HEAP_SIZE/u:GPU_MAX_ALLOC_PERCENT/u:GPU_SINGLE_ALLOC_PERCENT/u:ELECTRON_DISABLE_GPU_SANDBOX/u:ELECTRON_FORCE_WINDOW_MENU_BAR/u:MESA_NO_ERROR/u:vblank_mode/u"

set "ROCM_USE_WSL=1"
set "HSA_OVERRIDE_GFX_VERSION=12.0.1"
set "HSA_ENABLE_DXG_DETECTION=1"
set "TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1"
set "HSA_ENABLE_SDMA=0"
set "HSA_FORCE_FINE_GRAIN_PCIE=1"
set "GPU_MAX_HEAP_SIZE=100"
set "GPU_MAX_ALLOC_PERCENT=100"
set "GPU_SINGLE_ALLOC_PERCENT=100"
set "ELECTRON_DISABLE_GPU_SANDBOX=1"
set "ELECTRON_FORCE_WINDOW_MENU_BAR=1"
set "MESA_NO_ERROR=1"
set "vblank_mode=0"

:: 3. Check if Pinokio is installed in WSL
echo Checking Pinokio installation in WSL...
wsl -d Ubuntu-24.04 -- bash -c "which pinokio || echo 'Not found'" | findstr /C:"pinokio" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [!] Pinokio not found in WSL. Running setup...
    echo Please run Install-Pinokio-ROCm.bat first to install Pinokio.
    pause
    exit /b 1
)

:: 4. Automatically open default Windows browser to Pinokio UI
echo Opening Pinokio Web UI in Windows browser...
start "" "http://localhost:42000"

:: 5. Launch Pinokio in foreground with ROCm optimizations
echo Launching Pinokio ROCm backend in WSL...
wsl.exe -d Ubuntu-24.04 -u manat -- bash -c "if [ -f ~/pinokio-rocm.sh ]; then bash ~/pinokio-rocm.sh; elif [ -f ~/pinokio/pinokio-rocm.sh ]; then bash ~/pinokio/pinokio-rocm.sh; else pinokio --ozone-platform=x11 --disable-gpu-sandbox; fi"

if %ERRORLEVEL% neq 0 (
    echo.
    echo [*] Fallback direct launch...
    wsl.exe -d Ubuntu-24.04 -u manat -- pinokio --ozone-platform=x11 --disable-gpu-sandbox
)

echo.
echo Pinokio ROCm session closed.
pause