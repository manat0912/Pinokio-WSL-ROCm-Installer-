@echo off
setlocal

:: Target URL to open
set "URL=http://localhost:42000"

:: Function to open browser once
:OPEN_BROWSER
start "" "%URL%"
goto :CONTINUE

:: Function to wait for Pinokio to be ready on port 42000
:WAIT_FOR_PINOKIO
echo Waiting for Pinokio to start on port 42000...
set "ATTEMPTS=0"
set "MAX_ATTEMPTS=60"
:WAIT_LOOP
timeout /t 2 >nul
netstat -ano | findstr ":42000" | findstr "LISTENING" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Pinokio is ready!
    goto :OPEN_BROWSER
)
set /a ATTEMPTS+=1
if %ATTEMPTS% lss %MAX_ATTEMPTS% (
    goto :WAIT_LOOP
)
echo Timeout waiting for Pinokio. Opening browser anyway...
goto :OPEN_BROWSER

:CONTINUE
:: Check if Pinokio is already running
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
    wsl -- bash -c "export ROCM_PATH=/opt/rocm; export ROCM_USE_WSL=1; export HSA_ENABLE_DXG_DETECTION=1; export LD_LIBRARY_PATH=/usr/lib/wsl/lib:/opt/rocm/lib:/opt/rocm/lib64; export LD_PRELOAD=/opt/rocm/lib/libamdhip64.so:/opt/rocm/lib/libhsa-runtime64.so.1:/lib/x86_64-linux-gnu/libhsakmt.so.1; unset DISPLAY; export ELECTRON_OZONE_PLATFORM_HINT=wayland; export OZONE_PLATFORM=wayland; export XDG_SESSION_TYPE=wayland; export ELECTRON_ENABLE_WAYLAND=1; /opt/Pinokio/pinokio-bin --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-sandbox"
)

:: Wait for Pinokio to be ready and open browser
call :WAIT_FOR_PINOKIO

endlocal