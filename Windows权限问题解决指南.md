# Windows 权限问题解决指南

## 🚨 问题描述

在Windows上运行Flutter桌面应用时遇到的常见错误：

```
Error: ERROR_ACCESS_DENIED file system exception thrown while trying to create a symlink
```

这是因为Windows系统默认不允许普通用户创建符号链接，而Flutter桌面应用需要为插件创建符号链接。

## ✅ 解决方案

### 方案1：启用Windows开发者模式（推荐）

#### 步骤1：打开开发者设置
```powershell
# 自动打开设置页面
start ms-settings:developers
```

#### 步骤2：启用开发者模式
1. 在设置页面中找到 **"开发者模式"**
2. 点击切换开关启用
3. 确认弹出的警告对话框
4. **重启电脑**（重要！）

#### 步骤3：验证设置
重启后运行：
```powershell
.\start_desktop_en.ps1
```

### 方案2：使用管理员权限运行

#### 自动管理员模式（推荐）
使用我们提供的管理员脚本：
```powershell
.\start_desktop_admin.ps1
```
脚本会自动请求管理员权限并重启。

#### 手动管理员模式
1. 右键点击PowerShell图标
2. 选择 **"以管理员身份运行"**
3. 导航到项目目录
4. 运行启动脚本

### 方案3：手动清理缓存

有时清理缓存可以解决权限问题：
```powershell
# 清理Flutter缓存
flutter clean

# 清理Pub缓存
flutter pub cache clean

# 重新获取依赖
flutter pub get
```

### 方案4：修改本地安全策略（高级）

⚠️ **仅适用于企业用户或高级用户**

1. 按 `Win + R`，输入 `secpol.msc`
2. 导航到：**本地策略** > **用户权限分配**
3. 找到 **"创建符号链接"**
4. 双击并添加当前用户
5. 重启电脑

## 🔧 完整的故障排除流程

### 1. 检查当前状态
```powershell
# 检查是否以管理员身份运行
[Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent() | Format-List

# 检查Flutter版本
flutter --version

# 检查开发者模式状态
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense
```

### 2. 清理环境
```powershell
# 完全清理
flutter clean
flutter pub cache clean
Remove-Item -Recurse -Force .dart_tool -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
```

### 3. 重新配置
```powershell
# 配置镜像源
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"

# 重新获取依赖
flutter pub get
```

### 4. 尝试运行
```powershell
# 方式1：直接运行
flutter run -d windows

# 方式2：使用脚本
.\start_desktop_admin.ps1
```

## ⚙️ 高级选项

### 临时绕过符号链接
如果以上方法都不行，可以尝试禁用符号链接：

1. 编辑 `pubspec.yaml`
2. 在 `flutter:` 部分添加：
```yaml
flutter:
  uses-material-design: true
  generate: false
```

### 使用WSL2（Linux子系统）
如果Windows权限问题持续存在：
1. 安装WSL2
2. 在Linux环境中开发Flutter桌面应用
3. 使用X11转发显示Windows窗口

## 📋 验证清单

- [ ] 已启用Windows开发者模式
- [ ] 已重启电脑
- [ ] 配置了Flutter镜像源
- [ ] 清理了所有缓存
- [ ] 使用了正确的启动脚本
- [ ] 检查了杀毒软件设置
- [ ] 确认了Flutter版本兼容性

## 🆘 仍然无法解决？

### 收集诊断信息
```powershell
# 生成详细报告
flutter doctor -v > flutter_doctor_report.txt
flutter config > flutter_config_report.txt
echo $env:PATH > path_report.txt

# 检查权限
whoami /priv > privileges_report.txt
```

### 常见原因
1. **杀毒软件阻止**：添加Flutter目录到信任列表
2. **企业策略限制**：联系IT部门
3. **磁盘空间不足**：确保有足够空间
4. **权限继承问题**：检查文件夹权限设置
5. **网络代理干扰**：暂时禁用代理

### 替代方案
如果实在无法解决，考虑：
1. **使用Web版**：功能基本相同
2. **虚拟机**：在虚拟机中运行
3. **Docker容器**：容器化开发环境
4. **云开发环境**：使用GitHub Codespaces等

## 💡 预防措施

### 开发环境配置建议
1. **启用开发者模式**（一劳永逸）
2. **配置Flutter镜像源**（避免网络问题）
3. **定期更新Flutter**（获得最新修复）
4. **使用SSD硬盘**（提高IO性能）
5. **关闭实时杀毒扫描**（针对开发目录）

---

**记住：启用开发者模式是最简单有效的解决方案！** 🎯 