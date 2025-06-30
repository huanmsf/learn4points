# 智能答题助手 - PowerShell安装脚本
Write-Host "================================" -ForegroundColor Cyan
Write-Host "   智能答题助手 - 自动安装脚本" -ForegroundColor Cyan  
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# 检查Flutter是否已安装
try {
    $flutterVersion = flutter --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Flutter已安装，正在启动项目..." -ForegroundColor Green
        goto run_project
    }
} catch {
    Write-Host "📦 Flutter未安装，开始安装过程..." -ForegroundColor Yellow
}

# 检查是否有Git
try {
    git --version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Git not found"
    }
} catch {
    Write-Host "❌ 未检测到Git，请先安装Git" -ForegroundColor Red
    Write-Host "下载地址: https://git-scm.com/download/win" -ForegroundColor Yellow
    Read-Host "按Enter键退出"
    exit 1
}

# 下载Flutter
Write-Host "📥 正在下载Flutter..." -ForegroundColor Blue
if (-not (Test-Path "C:\flutter")) {
    New-Item -ItemType Directory -Path "C:\flutter" -Force | Out-Null
}

Set-Location "C:\"
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# 添加到PATH（临时）
$env:PATH += ";C:\flutter\bin"

Write-Host "🔧 配置Flutter..." -ForegroundColor Blue
flutter doctor

:run_project
Set-Location $PSScriptRoot

Write-Host ""
Write-Host "🚀 开始运行项目..." -ForegroundColor Green
Write-Host ""

# 获取依赖
Write-Host "📦 安装项目依赖..." -ForegroundColor Blue
flutter pub get

# 生成代码
Write-Host "🔨 生成必要代码..." -ForegroundColor Blue
flutter packages pub run build_runner build --delete-conflicting-outputs

# 创建平台文件
Write-Host "📱 生成平台配置..." -ForegroundColor Blue
flutter create --platforms=android,ios .

# 运行项目
Write-Host "🎯 启动应用..." -ForegroundColor Green
flutter run

Read-Host "按Enter键退出" 