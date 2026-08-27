@echo off
setlocal

:: Define a temporary lock file
set "LOCK_FILE=%TEMP%\pinokio_browser.lock"

:: Delete the lock file from previous sessions when the script starts
if exist "%LOCK_FILE%" del "%LOCK_FILE%"

:: Target URL to open
set "URL=http://localhost:42000"

:: Launch browser only if the lock file does not exist
if not exist "%LOCK_FILE%" (
    echo Launching Pinokio browser interface...
    echo locked > "%LOCK_FILE%"
    start "" "%URL%"
)

:: Your original WSL / Pinokio launch commands go below this line
:: Example: wsl -d Ubuntu-24.04 -u manat bash -c "cd ~/pinokio && ./run.sh"

:: If Pinokio is already running, just focus the existing browser tab and exit
netstat -ano | findstr ":42000" | findstr "LISTENING" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [*] Pinokio is already running. Opening existing session...
    start "" "http://localhost:42000"
    exit /b 0
)

echo Starting Pinokio with ROCm GPU acceleration via WSL...
wsl -- bash -c "export ROCM_PATH=/opt/rocm; export ROCM_USE_WSL=1; export HSA_ENABLE_DXG_DETECTION=1; export LD_LIBRARY_PATH=/usr/lib/wsl/lib:/opt/rocm/lib:/opt/rocm/lib64; export LD_PRELOAD=/opt/rocm/lib/libamdhip64.so:/opt/rocm/lib/libhsa-runtime64.so.1:/lib/x86_64-linux-gnu/libhsakmt.so.1; unset DISPLAY; export ELECTRON_OZONE_PLATFORM_HINT=wayland; export OZONE_PLATFORM=wayland; export XDG_SESSION_TYPE=wayland; export ELECTRON_ENABLE_WAYLAND=1; /opt/Pinokio/pinokio-bin --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-gpu"
if errorlevel 1 (
    echo.
    echo Pinokio exited with an error. Trying with GPU fallback...
    wsl -- bash -c "export ROCM_PATH=/opt/rocm; export ROCM_USE_WSL=1; export HSA_ENABLE_DXG_DETECTION=1; export LD_LIBRARY_PATH=/usr/lib/wsl/lib:/opt/rocm/lib:/opt/rocm/lib64; export LD_PRELOAD=/opt/opt/rocm/lib/libamdhip64.so:/opt/rocm/lib/libhsa-runtime64.so.1:/lib/x86_64-linux-gnu/libhsakmt.so.1; unset DISPLAY; export ELECTRON_OZONE_PLATFORM_HINT=wayland; export OZONE_PLATFORM=wayland; export XDG_SESSION_TYPE=wayland; export ELECTRON_ENABLE_WAYLAND=1; /opt/Pinokio/pinokio-bin --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-sandbox"
)

endlocal