@echo off
echo Starting Gemma Health Edge Backend...
echo.

cd /d "%~dp0backend"

REM Check Python availability
where python >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found in PATH
    echo        Please install Python 3.10+ from python.org
    pause
    exit /b 1
)

REM Install dependencies if needed
if not exist "requirements.txt" (
    echo No requirements.txt found, please ensure dependencies are installed
    pause
    exit /b 1
)

echo Installing/updating dependencies...
python -m pip install -r requirements.txt -q

REM Start the backend server
echo.
echo Starting backend server on http://127.0.0.1:8080
echo Press Ctrl+C to stop the server
echo.
python main.py

pause
