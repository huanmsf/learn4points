# 智能答题助手 - 桌面版功能说明

## 🖥️ 桌面版概述

桌面版是智能答题助手的增强版本，在保留Web版所有功能的基础上，新增了强大的桌面专属功能。

### 支持平台
- ✅ **Windows** (Windows 10/11)
- ✅ **macOS** (macOS 10.14+)
- ✅ **Linux** (Ubuntu 18.04+)

## 🚀 快速启动

### Windows
```powershell
# 方式1：使用启动脚本（推荐）
.\start_desktop.ps1

# 方式2：直接运行
flutter run -d windows

# 方式3：构建后运行
flutter build windows --release
.\build\windows\x64\runner\Release\smart_quiz_helper.exe
```

### macOS
```bash
# 直接运行
flutter run -d macos

# 构建后运行
flutter build macos --release
open build/macos/Build/Products/Release/smart_quiz_helper.app
```

### Linux
```bash
# 直接运行
flutter run -d linux

# 构建后运行
flutter build linux --release
./build/linux/x64/release/bundle/smart_quiz_helper
```

## ✨ 桌面版独有功能

### 1. 🎯 全局热键支持
桌面版支持系统级全局热键，即使应用在后台也能快速操作：

| 热键组合 | 功能描述 |
|---------|----------|
| `Ctrl + Shift + S` | 快速全屏截图 |
| `Ctrl + Shift + A` | 交互式区域截图 |
| `Ctrl + Shift + Q` | 显示/隐藏主窗口 |
| `Ctrl + Shift + R` | 开始/停止自动答题 |
| `Ctrl + Shift + P` | 暂停/恢复功能 |

### 2. 📊 系统托盘集成
- **最小化到托盘**：关闭窗口时自动隐藏到系统托盘
- **右键菜单**：托盘图标右键显示功能菜单
- **单击切换**：单击托盘图标快速显示/隐藏窗口
- **状态提示**：托盘图标显示当前工作状态

### 3. 🖼️ 高级截图功能
- **区域选择截图**：鼠标拖拽选择任意区域
- **窗口自动隐藏**：截图时自动隐藏应用窗口
- **高DPI支持**：适配高分辨率显示器
- **多显示器支持**：支持多屏环境截图

### 4. 🪟 窗口管理功能
- **窗口置顶**：保持窗口在最前端显示
- **透明度控制**：调节窗口透明度(0-100%)
- **尺寸记忆**：记住用户设置的窗口大小和位置
- **全屏模式**：支持全屏显示模式

### 5. 🔄 自动更新
- **版本检查**：启动时自动检查新版本
- **后台下载**：静默下载更新包
- **增量更新**：仅下载必要的更新文件
- **回滚功能**：更新失败时自动回滚

### 6. 🎨 桌面通知
- **原生通知**：使用系统原生通知样式
- **答案提示**：识别到答案时弹出通知
- **错误提醒**：OCR或AI服务异常时提醒
- **状态更新**：重要状态变化实时通知

## 🛠️ 配置说明

### 桌面特有配置
在 `lib/utils/config.dart` 中添加桌面版配置：

```dart
class DesktopConfig {
  // 热键配置
  static const bool enableGlobalHotkeys = true;
  static const Map<String, String> hotkeys = {
    'screenshot': 'Ctrl+Shift+S',
    'region_screenshot': 'Ctrl+Shift+A',
    'toggle_window': 'Ctrl+Shift+Q',
    'toggle_auto_answer': 'Ctrl+Shift+R',
    'pause_resume': 'Ctrl+Shift+P',
  };
  
  // 窗口配置
  static const bool enableSystemTray = true;
  static const bool minimizeToTray = true;
  static const bool rememberWindowState = true;
  static const double defaultOpacity = 1.0;
  static const bool defaultAlwaysOnTop = false;
  
  // 自动更新配置
  static const bool enableAutoUpdate = true;
  static const String updateCheckUrl = 'https://api.github.com/repos/your-repo/releases/latest';
  static const int updateCheckInterval = 24; // 小时
}
```

## 📋 依赖说明

桌面版使用的主要依赖包：

```yaml
dependencies:
  # 桌面平台专用依赖
  screen_capturer: ^0.2.2      # 屏幕截图
  window_manager: ^0.3.7       # 窗口管理
  hotkey_manager: ^0.2.3       # 全局热键
  system_tray: ^2.0.3          # 系统托盘
  desktop_notifications: ^0.6.3 # 桌面通知
  auto_updater: ^0.3.1         # 自动更新
  file_picker: ^8.0.0+1        # 文件选择器
  clipboard_watcher: ^0.2.1    # 剪贴板监听
  pasteboard: ^0.2.0           # 剪贴板操作
  url_launcher: ^6.2.2         # URL启动器
```

## 🎮 使用体验对比

| 功能特性 | Web版 | 桌面版 |
|---------|-------|--------|
| 基础答题功能 | ✅ | ✅ |
| OCR识别 | ✅ | ✅ |
| AI查询 | ✅ | ✅ |
| 数据库存储 | ✅ | ✅ |
| 全局热键 | ❌ | ✅ |
| 系统托盘 | ❌ | ✅ |
| 区域截图 | ❌ | ✅ |
| 窗口管理 | ❌ | ✅ |
| 原生通知 | ❌ | ✅ |
| 自动更新 | ❌ | ✅ |
| 离线使用 | ❌ | ✅ |
| 性能表现 | 一般 | 优秀 |
| 启动速度 | 快 | 中等 |
| 内存占用 | 低 | 中等 |

## 🚨 注意事项

### Windows平台
- 需要Windows 10或更高版本
- 首次运行可能需要管理员权限
- 某些杀毒软件可能误报，需要添加信任

### macOS平台
- 需要授予屏幕录制权限
- 需要授予辅助功能权限
- 可能需要在安全设置中允许应用运行

### Linux平台
- 需要安装相关系统库
- 某些功能可能需要额外配置
- 不同发行版可能有兼容性差异

## 🔧 故障排除

### 热键不工作
1. 检查是否有其他应用占用了相同热键
2. 确认应用具有必要的系统权限
3. 尝试重新启动应用

### 截图功能异常
1. **Windows**: 检查是否开启了DPI感知
2. **macOS**: 确认屏幕录制权限已授予
3. **Linux**: 检查X11或Wayland环境配置

### 系统托盘不显示
1. 确认系统托盘功能已开启
2. 检查任务栏设置中的通知区域配置
3. 尝试重启系统托盘服务

### 窗口管理问题
1. 检查是否有窗口管理器冲突
2. 确认应用具有窗口操作权限
3. 重置窗口状态到默认值

## 📞 技术支持

如果遇到桌面版特有的问题，请：

1. 查看应用日志文件
2. 检查系统权限设置
3. 尝试以管理员权限运行
4. 联系技术支持并提供：
   - 操作系统版本
   - 应用版本号
   - 错误日志
   - 复现步骤

---

**桌面版让智能答题助手更强大，体验更流畅！** 🚀 