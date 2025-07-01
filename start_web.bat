@echo off
chcp 65001 >nul
title Smart Quiz Helper - Web Version

echo.
echo ========================================
echo   Smart Quiz Helper - Web Version
echo ========================================
echo.

REM 配置Flutter中国镜像
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
set PUB_HOSTED_URL=https://pub.flutter-io.cn
echo [OK] Flutter China mirror configured

REM 检查端口占用
echo [OK] Checking port 8080...
netstat -ano | findstr :8080 >nul
if %ERRORLEVEL% == 0 (
    echo [WARN] Port 8080 is in use, cleaning...
    for /f "tokens=5" %%i in ('netstat -ano ^| findstr :8080') do (
        taskkill /PID %%i /F >nul 2>&1
    )
    timeout /t 2 >nul
    echo [OK] Port cleaned
)

REM 清理并获取依赖
echo [OK] Cleaning Flutter cache...
flutter clean >nul

echo [OK] Getting dependencies...
flutter pub get

if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to get dependencies
    pause
    exit /b 1
)

echo.
echo [OK] Starting Smart Quiz Helper - Web Version...
echo [OK] Features:
echo     * OCR text recognition
echo     * AI answer service
echo     * Question database
echo     * Answer history
echo.
echo [NOTE] Web version limitations:
echo [NOTE] - No auto screenshot support
echo [NOTE] - Manual image upload required
echo.
echo [OK] App will open in browser: http://localhost:8080
echo [OK] Press Ctrl+C to stop the app
echo.

REM 启动Flutter Web应用
flutter run -d chrome --web-port=8080

echo.
echo [OK] App stopped
pause 