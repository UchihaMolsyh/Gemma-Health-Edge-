@echo off
setlocal EnableDelayedExpansion
title Gemma Health Edge — Remote Tunnel
color 0B
echo.
echo  ============================================================
echo   Gemma Health Edge — Cloudflare Public Tunnel
echo   Share your local AI with anyone over the internet.
echo   Free. No account. No login.
echo  ============================================================
echo.

set "PORT=5500"

:: Try to read web_port from config.json using PowerShell
for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "$c=Get-Content -Raw 'config.json' | ConvertFrom-Json; $c.web_port" 2^>nul`) do (
    if not "%%P"=="" set "PORT=%%P"
)
echo  [CFG] Tunneling Web UI: http://localhost:%PORT%
echo.

:: Use local cloudflared.exe if available, otherwise try system PATH
set "CF_BIN="

if exist "%~dp0cloudflared.exe" (
    set "CF_BIN=%~dp0cloudflared.exe"
    echo  [OK] Using bundled cloudflared.exe
    goto :start_tunnel
)

where cloudflared >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    set "CF_BIN=cloudflared"
    echo  [OK] Using system-installed cloudflared
    goto :start_tunnel
)

:: Auto-download
echo  cloudflared not found. Downloading latest release...
curl -# -L -o "%~dp0cloudflared.exe" ^
    "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
if !ERRORLEVEL! NEQ 0 (
    echo.
    echo  [ERROR] Download failed. Please download manually from:
    echo          https://github.com/cloudflare/cloudflared/releases
    pause & exit /b 1
)
set "CF_BIN=%~dp0cloudflared.exe"
echo  [OK] Downloaded cloudflared.exe
echo.

:start_tunnel
echo  Starting tunnel... your public URL will appear below.
echo  Share it with anyone — it expires when you close this window.
echo.
echo  Press Ctrl+C to stop the tunnel.
echo  ============================================================
echo.

"%CF_BIN%" tunnel --url http://127.0.0.1:%PORT%

echo.
echo  Tunnel stopped.
pause
