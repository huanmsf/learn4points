@echo off
echo ================================
echo   智能答题助手 - 自动安装脚本
echo ================================
echo.

REM 检查Flutter是否已安装
flutter --version >nul 2>&1
if %errorlevel% == 0 (
    echo ✅ Flutter已安装，正在启动项目...
    goto run_project
)

echo 📦 Flutter未安装，开始安装过程...
echo.

REM 创建Flutter目录
if not exist "C:\flutter" (
    echo 📁 创建Flutter目录...
    mkdir "C:\flutter" 2>nul
)

REM 检查是否有Git
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 未检测到Git，请先安装Git
    echo 下载地址: https://git-scm.com/download/win
    pause
    exit /b 1
)

echo 📥 正在下载Flutter...
cd /d C:\
git clone https://github.com/flutter/flutter.git -b stable --depth 1

REM 添加到PATH（临时）
set PATH=%PATH%;C:\flutter\bin

echo 🔧 配置Flutter...
flutter doctor

:run_project
cd /d "%~dp0"

echo.
echo 🚀 开始运行项目...
echo.

REM 获取依赖
echo 📦 安装项目依赖...
flutter pub get

REM 生成代码
echo 🔨 生成必要代码...
flutter packages pub run build_runner build --delete-conflicting-outputs

REM 创建平台文件
echo 📱 生成平台配置...
flutter create --platforms=android,ios .

REM 运行项目
echo 🎯 启动应用...
flutter run

pause 