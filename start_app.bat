@echo off
echo Smart Answer Assistant Startup Script
echo =====================================

echo Checking port 8080 usage...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080 ^| findstr LISTENING') do (
    echo Found process %%a using port 8080
    echo Terminating process...
    taskkill /f /pid %%a >nul 2>&1
    if !errorlevel! equ 0 (
        echo Successfully terminated process %%a
    ) else (
        echo Failed to terminate process, may need admin rights
    )
)

echo Cleaning Flutter cache...
flutter clean >nul 2>&1

echo Getting dependencies...
flutter pub get

echo Starting Flutter Web app...
echo App will run at http://localhost:8080
echo Press Ctrl+C to stop the app
echo =====================================

flutter run -d chrome --web-hostname localhost --web-port 8080 