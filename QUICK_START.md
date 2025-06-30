# 🚀 智能答题助手 - 快速启动指南

## 方法一：使用自动化脚本（推荐）

### Windows批处理脚本
```cmd
双击运行 setup_and_run.bat
```

### PowerShell脚本
```powershell
右键 setup_and_run.ps1 -> 使用PowerShell运行
```

## 方法二：手动安装步骤

### 第1步：安装Flutter

#### 选项A：手动下载
1. 访问 https://flutter.dev/docs/get-started/install/windows
2. 下载Flutter SDK zip文件
3. 解压到 `C:\flutter`
4. 添加 `C:\flutter\bin` 到系统PATH环境变量

#### 选项B：使用Git（如果网络允许）
```cmd
cd C:\
git clone https://github.com/flutter/flutter.git -b stable
set PATH=%PATH%;C:\flutter\bin
```

### 第2步：验证安装
```cmd
flutter doctor
```

### 第3步：运行项目
```cmd
# 进入项目目录
cd E:\cursorProjects\learn4points

# 安装依赖
flutter pub get

# 生成代码
flutter packages pub run build_runner build --delete-conflicting-outputs

# 创建平台配置
flutter create --platforms=android,ios .

# 运行项目
flutter run
```

## 方法三：在线体验

如果本地安装遇到问题，可以使用在线Flutter环境：

1. **DartPad** - https://dartpad.dev/
   - 复制 `lib/main.dart` 代码
   - 在线运行Flutter Web版本

2. **FlutLab** - https://flutlab.io/
   - 上传整个项目
   - 在线开发和运行

3. **Replit** - https://replit.com/
   - 创建Flutter项目
   - 导入代码文件

## 常见问题解决

### Q1: flutter命令未找到
**解决方案：**
- 确保Flutter已正确安装到 `C:\flutter`
- 确保 `C:\flutter\bin` 已添加到PATH环境变量
- 重启命令行/PowerShell窗口

### Q2: 依赖安装失败
**解决方案：**
```cmd
flutter clean
flutter pub cache repair
flutter pub get
```

### Q3: 生成代码失败
**解决方案：**
```cmd
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Q4: 平台配置问题
**解决方案：**
- 确保安装了Android Studio（Android开发）
- 确保安装了Xcode（iOS开发，仅macOS）
- 运行 `flutter doctor` 检查环境

### Q5: 网络连接问题
**解决方案：**
- 配置代理（如果需要）
- 使用国内镜像：
```cmd
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

## API配置

在运行项目前，请配置必要的API密钥：

1. 打开 `lib/utils/config.dart`
2. 替换以下占位符：
   - `YOUR_BAIDU_OCR_API_KEY` - 百度OCR API密钥
   - `YOUR_BAIDU_OCR_SECRET_KEY` - 百度OCR Secret密钥
   - `YOUR_OPENAI_API_KEY` - OpenAI API密钥（可选）
   - 其他API密钥（可选）

## 支持的平台

- ✅ Android (需要Android Studio)
- ✅ iOS (需要Xcode，仅macOS)
- ✅ Web (Chrome浏览器)
- ⚠️ Windows/macOS/Linux桌面版（实验性）

## 技术支持

如果遇到问题，请：
1. 查看 `SETUP.md` 详细文档
2. 运行 `flutter doctor` 检查环境
3. 查看项目README.md
4. 提交Issue到项目仓库

## 项目结构
```
learn4points/
├── lib/              # 核心代码
├── assets/           # 资源文件
├── pubspec.yaml      # 依赖配置
├── setup_and_run.bat # Windows自动化脚本
├── setup_and_run.ps1 # PowerShell自动化脚本
└── QUICK_START.md    # 本文档
```

祝您使用愉快！ 🎉 