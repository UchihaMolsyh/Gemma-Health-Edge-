@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  🏥 Gemma Health Edge — Unified Launcher v3.1
::  Starts: Ollama + llama.cpp + Middleman + UI
:: ============================================================

title Gemma Health Edge - Unified Launcher

:: --- 1. SETUP & DEPENDENCY CHECK ---
echo.
echo [1/6] Checking for required files...

:: Check for Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python not found. Please install Python 3.10+
    pause & exit /b 1
)

:: Check for core files, run setup.py if missing
if not exist "backend\models\gemma-4-E4B-it-Q4_K_M.gguf" (
    echo [INFO] Model files missing. Running setup...
    python setup.py
    if !errorlevel! neq 0 ( echo [ERROR] Setup failed. & pause & exit /b 1 )
)

if not exist "backend\llama-server\llama-server.exe" (
    echo [INFO] llama-server missing. Running setup...
    python setup.py
    if !errorlevel! neq 0 ( echo [ERROR] Setup failed. & pause & exit /b 1 )
)

:: --- 2. OLLAMA SERVICE ---
echo.
echo [2/6] Starting Ollama Service...
:: Start ollama serve in background (if not already running)
netstat -ano | findstr ":11434" | findstr "LISTENING" >nul 2>&1
if %errorlevel% neq 0 (
    start /B "Ollama Service" ollama serve >nul 2>&1
    echo [OK] Ollama starting...
) else (
    echo [OK] Ollama already running.
)

:: --- 3. HARDWARE DETECTION ---
echo.
echo [3/6] Detecting optimal hardware...

set "gpuName=Generic CPU"
set "vramGB=0"
set "hasCUDA=0"
set "hasRDNA=0"
set "hasNPU=0"

for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "Get-CimInstance Win32_VideoController | ForEach-Object { $v = [math]::Round($_.AdapterRAM / 1GB, 1); if ($v -le 1) { $mem = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 2GB; $v = [math]::Round($mem, 1) }; $_.Name + '|' + $v }" 2^>nul`) do (
    set "gpuLine=%%G"
    for /f "tokens=1,2 delims=|" %%A in ("!gpuLine!") do (
        set "curGpu=%%A"
        set "curVram=%%B"
    )
    echo !curGpu! | findstr /i "NVIDIA" >nul 2>&1
    if not errorlevel 1 ( set "hasCUDA=1" & set "gpuName=!curGpu!" & set "vramGB=!curVram!" )
    echo !curGpu! | findstr /i "AMD Radeon" >nul 2>&1
    if not errorlevel 1 ( if "!hasCUDA!"=="0" ( set "hasRDNA=1" & set "gpuName=!curGpu!" & set "vramGB=!curVram!" ) )
)

for /f "usebackq delims=" %%N in (`powershell -NoProfile -Command "Get-CimInstance Win32_PnPEntity | Where-Object { ($_.Name -match 'Neural|NPU|Accelerator|AI Boost') -and ($_.Name -notmatch 'USB') } | Select-Object -First 1 | ForEach-Object { $_.Name }" 2^>nul`) do (
    set "hasNPU=1" & set "npuName=%%N"
)

for /f "usebackq delims=" %%C in (`powershell -NoProfile -Command "$t = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors; if ($t -gt 2) { [math]::Floor($t / 2) } else { $t }" 2^>nul`) do set "cpuThreads=%%C"
if not defined cpuThreads set "cpuThreads=4"

echo [GPU] !gpuName! (!vramGB! GB VRAM)
if "%hasNPU%"=="1" echo [NPU] Detected: !npuName!

:: Save to hardware.json
powershell -NoProfile -Command "$hw = @{ gpu = '!gpuName!'; vram = [double]!vramGB!; npu = %hasNPU% -eq 1; cpu = %cpuThreads% }; $hw | ConvertTo-Json | Out-File -Encoding UTF8 hardware.json" 2>nul

:: --- 4. START LLAMA.CPP SERVER ---
echo.
echo [4/6] Starting local llama.cpp server...

set "ngl=0"
if "%hasCUDA%"=="1" (
    set "ngl=99"
    if !vramGB! LSS 4 set "ngl=20"
    if !vramGB! GEQ 4 if !vramGB! LSS 8 set "ngl=35"
) else if "%hasRDNA%"=="1" (
    set "ngl=99"
    if !vramGB! LSS 4 set "ngl=24"
)

:: Start llama-server on port 8081
netstat -ano | findstr ":8081" | findstr "LISTENING" >nul 2>&1
if %errorlevel% neq 0 (
    start /B "Gemma llama.cpp" "backend\llama-server\llama-server.exe" -m backend\models\gemma-4-E4B-it-Q4_K_M.gguf --mmproj backend\models\mmproj-gemma-4-E4B-it-bf16.gguf --port 8081 --host 127.0.0.1 -ngl !ngl! -c 4096 -t %cpuThreads% --no-mmap >llama_server.log 2>&1
    echo [OK] llama.cpp started on port 8081
) else (
    echo [OK] llama.cpp already running.
)

:: --- 5. START MAIN BACKEND (MIDDLEMAN) ---
echo.
echo [5/6] Starting Gemma Middleman...

:: Kill existing gateway if running on 8080 (from config.json)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8080" ^| findstr "LISTENING" 2^>nul') do taskkill /F /PID %%a >nul 2>&1

:: Start main.py (handles Gateway on 8080 and 11434 proxy)
start /B "Gemma Backend" python backend/main.py >backend.log 2>&1
echo [OK] Backend started.

:: --- 6. LAUNCH UI ---
echo.
echo [6/6] Launching UI...
timeout /t 3 /nobreak >nul
start "" "http://127.0.0.1:8080"

echo.
echo ========================================================
echo  Ready! Ollama, llama.cpp, and Middleman are online.
echo  ========================================================
echo.
echo  Keep this window open to maintain the connection.
echo  Close this window to stop all local servers.
echo.

if "%1"=="--silent" exit /b 0

pause >nul

:: CLEANUP
echo Stopping local servers...
taskkill /F /IM llama-server.exe >nul 2>&1
taskkill /F /FI "WINDOWTITLE eq Gemma Backend" /IM python.exe >nul 2>&1
exit /b 0
