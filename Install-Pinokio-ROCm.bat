@echo off
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrative Privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

title Pinokio ROCm One-Click Installer - AMD AI Pro 9700
cd /d "%~dp0"

echo ====================================================================
echo      PINOKIO ROCm ONE-CLICK INSTALLER FOR AMD AI PRO 9700
echo               Developer: Mana Turipa (Open Source)
echo ====================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup-Pinokio-ROCm.ps1"

echo.
echo ====================================================================
echo  Installation Completed. Press any key to exit.
echo ====================================================================
pause
