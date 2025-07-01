@echo off
chcp 65001 >nul
title 智能答题助手 - 桌面版

echo.
echo ========================================
echo     智能答题助手 - 桌面版启动脚本
echo ========================================
echo.

REM 配置Flutter中国镜像
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
set PUB_HOSTED_URL=https://pub.flutter-io.cn
echo [√] Flutter中国镜像配置完成

REM 检查Windows开发者模式
echo [√] 检查Windows开发者模式...
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo.
    echo [!] 警告: 检测到可能需要开发者模式
    echo [!] 如果出现符号链接错误，请按以下步骤操作:
    echo     1. Win+I 打开设置
    echo     2. 更新和安全 ^> 开发者选项
    echo     3. 启用"开发者模式"
    echo     4. 重启电脑后重新运行此脚本
    echo.
    set /p continue="是否继续启动? (y/N): "
    if /i not "%continue%"=="y" (
        echo [×] 用户取消启动
        pause
        exit /b 1
    )
)

REM 获取依赖
echo [√] 获取项目依赖...
flutter pub get

if %ERRORLEVEL% neq 0 (
    echo [×] 依赖获取失败
    echo [!] 可能是符号链接权限问题，请启用开发者模式
    pause
    exit /b 1
)

echo.
echo [√] 启动桌面版智能答题助手...
echo [√] 桌面版功能特性:
echo     ✓ 全局热键支持
echo     ✓ 系统托盘集成  
echo     ✓ 自动截图功能
echo     ✓ 区域截图选择
echo     ✓ 窗口管理
echo     ✓ OCR文字识别
echo     ✓ 豆包AI答题
echo.
echo [√] 全局热键说明:
echo     Ctrl+Shift+S: 快速截图
echo     Ctrl+Shift+A: 区域截图
echo     Ctrl+Shift+Q: 显示/隐藏窗口
echo     Ctrl+Shift+R: 开始/停止自动答题
echo.

REM 启动Flutter桌面应用
flutter run -d windows

echo.
echo [√] 应用已停止
pause 