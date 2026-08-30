@echo off
setlocal EnableExtensions

set "URL=http://localhost:42000"

:: ---------------------------------------------------------------------------
:: 1. If Pinokio is already listening on 42000, open the UI once and exit.
:: ---------------------------------------------------------------------------
netstat -ano | findstr ":42000" | findstr "LISTENING" >nul 2>&1
if %ERRORLEVEL% equ 0 goto :OPEN_BROWSER

:: ---------------------------------------------------------------------------
:: 2. Launch Pinokio (WSL + ROCm) in its own window, in the background.
:: ---------------------------------------------------------------------------
echo Starting Pinokio with ROCm GPU acceleration via WSL...
start "Pinokio ROCm WSL" wsl -- bash -c "export ROCM_PATH=/opt/rocm; export ROCM_USE_WSL=1; export HSA_ENABLE_DXG_DETECTION=1; export LD_LIBRARY_PATH=/usr/lib/wsl/lib:/opt/rocm/lib:/opt/rocm/lib64; export LD_PRELOAD=/opt/rocm/lib/libamdhip64.so:/opt/rocm/lib/libhsa-runtime64.so.1:/lib/x86_64-linux-gnu/libhsakmt.so.1; unset DISPLAY; export ELECTRON_OZONE_PLATFORM_HINT=wayland; export OZONE_PLATFORM=wayland; export XDG_SESSION_TYPE=wayland; export ELECTRON_ENABLE_WAYLAND=1; /opt/Pinokio/pinokio-bin --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-gpu"

:: ---------------------------------------------------------------------------
:: 3. Wait for the port to come up, then open the UI once.
:: ---------------------------------------------------------------------------
echo Waiting for Pinokio to start on port 42000...
set "ATTEMPTS=0"
set "MAX_ATTEMPTS=60"
:WAIT_LOOP
timeout /t 2 >nul
netstat -ano | findstr ":42000" | findstr "LISTENING" >nul 2>&1
if %ERRORLEVEL% equ 0 goto :OPEN_BROWSER
set /a ATTEMPTS+=1
if %ATTEMPTS% lss %MAX_ATTEMPTS% goto :WAIT_LOOP

:: ---------------------------------------------------------------------------
:: 4. Timed out - try the GPU fallback once.
:: ---------------------------------------------------------------------------
echo Pinokio did not start. Trying GPU fallback...
start "Pinokio ROCm WSL (fallback)" wsl -- bash -c "export ROCM_PATH=/opt/rocm; export ROCM_USE_WSL=1; export HSA_ENABLE_DXG_DETECTION=1; export LD_LIBRARY_PATH=/usr/lib/wsl/lib:/opt/rocm/lib:/opt/rocm/lib64; export LD_PRELOAD=/opt/rocm/lib/libamdhip64.so:/opt/rocm/lib/libhsa-runtime64.so.1:/lib/x86_64-linux-gnu/libhsakmt.so.1; unset DISPLAY; export ELECTRON_OZONE_PLATFORM_HINT=wayland; export OZONE_PLATFORM=wayland; export XDG_SESSION_TYPE=wayland; export ELECTRON_ENABLE_WAYLAND=1; /opt/Pinokio/pinokio-bin --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-sandbox"
set "ATTEMPTS=0"
:WAIT_LOOP2
timeout /t 2 >nul
netstat -ano | findstr ":42000" | findstr "LISTENING" >nul 2>&1
if %ERRORLEVEL% equ 0 goto :OPEN_BROWSER
set /a ATTEMPTS+=1
if %ATTEMPTS% lss %MAX_ATTEMPTS% goto :WAIT_LOOP2
echo Timeout waiting for Pinokio. Opening browser anyway...

:: ---------------------------------------------------------------------------
:: 5. Open the Pinokio UI exactly once.
:: ---------------------------------------------------------------------------
:OPEN_BROWSER
start "" "%URL%"

endlocal
