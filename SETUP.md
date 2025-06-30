# 智能答题助手 - 项目设置指南

## 环境要求

- Flutter SDK >= 3.10.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- Android SDK (Android开发)
- Xcode (iOS开发，仅macOS)

## 项目初始化

### 1. 获取依赖

```bash
flutter pub get
```

### 2. 生成代码

项目使用了代码生成，需要运行以下命令生成必要的文件：

```bash
# 生成Hive适配器和JSON序列化代码
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 3. 添加资源文件

在 `assets/fonts/` 目录下添加字体文件：
- `PingFang-Regular.ttf`

在 `assets/images/` 目录下添加应用图标和图片资源。

### 4. 平台配置

#### Android配置

创建 `android/` 目录并配置：

```bash
flutter create --platforms=android .
```

然后编辑 `android/app/src/main/AndroidManifest.xml` 添加权限：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

#### iOS配置

创建 `ios/` 目录并配置：

```bash
flutter create --platforms=ios .
```

然后编辑 `ios/Runner/Info.plist` 添加权限：

```xml
<key>NSCameraUsageDescription</key>
<string>需要相机权限进行截图识别</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册进行图片识别</string>
```

## API配置

### 1. OCR服务配置

在 `lib/services/ocr_service.dart` 中配置：
- 百度OCR API密钥
- Google ML Kit配置

### 2. AI服务配置

在 `lib/services/answer_service.dart` 中配置：
- ChatGPT API密钥
- 百度文心一言API密钥

### 3. 搜索服务配置

配置搜索API：
- 百度搜索API
- 必应搜索API

## 运行项目

### 开发模式

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# 调试模式
flutter run --debug
```

### 构建发布版本

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 目录结构

```
smart_quiz_helper/
├── lib/
│   ├── models/          # 数据模型
│   ├── services/        # 服务层
│   ├── utils/           # 工具类
│   ├── screens/         # 页面
│   ├── widgets/         # 组件
│   └── main.dart        # 入口文件
├── assets/              # 资源文件
│   ├── images/          # 图片
│   ├── icons/           # 图标
│   └── fonts/           # 字体
├── android/             # Android平台代码
├── ios/                 # iOS平台代码
└── pubspec.yaml         # 依赖配置
```

## 常见问题

### 1. 依赖冲突

如果遇到依赖冲突，尝试：

```bash
flutter clean
flutter pub get
```

### 2. 代码生成失败

确保安装了所有必要的dev依赖：

```bash
flutter pub deps
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 3. 权限问题

确保在AndroidManifest.xml和Info.plist中正确配置了所有必要的权限。

### 4. API配置

确保所有API密钥都已正确配置，并且账户有足够的配额。

## 调试建议

1. 使用 `flutter logs` 查看日志
2. 使用 `flutter doctor` 检查环境
3. 使用 `flutter analyze` 检查代码质量
4. 使用 `flutter test` 运行测试（如果有）

## 部署建议

1. 为生产环境配置不同的API密钥
2. 启用代码混淆和压缩
3. 测试所有目标设备和系统版本
4. 配置应用签名和证书 