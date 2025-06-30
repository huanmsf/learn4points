# 豆包AI配置指南

## 1. 申请豆包AI账户

1. 访问火山引擎官网：https://www.volcengine.com/
2. 注册并登录账户
3. 进入豆包AI产品页面：https://www.volcengine.com/product/doubao
4. 开通豆包AI服务

## 2. 获取API密钥

1. 登录火山引擎控制台
2. 导航到"豆包"或"方舟"服务
3. 创建应用并获取API Key
4. 记录以下信息：
   - API Key
   - 模型名称（如：doubao-lite-32k、doubao-pro-4k等）
   - API端点URL

## 3. 配置应用

打开 `lib/utils/config.dart` 文件，找到豆包AI配置部分：

```dart
/// 字节跳动豆包AI配置
/// 申请地址: https://www.volcengine.com/product/doubao
static const String doubaoApiKey = 'YOUR_DOUBAO_API_KEY';
static const String doubaoBaseUrl = 'https://ark.cn-beijing.volces.com/api/v3';
static const String doubaoModel = 'doubao-lite-32k'; // 或其他可用模型
```

将 `YOUR_DOUBAO_API_KEY` 替换为你的实际API密钥。

## 4. 配置示例

```dart
/// 字节跳动豆包AI配置
static const String doubaoApiKey = 'sk-1234567890abcdef...'; // 你的实际API Key
static const String doubaoBaseUrl = 'https://ark.cn-beijing.volces.com/api/v3';
static const String doubaoModel = 'doubao-lite-32k';
```

## 5. 可用模型

根据你的需求选择合适的模型：

- `doubao-lite-32k` - 轻量版，速度快，适合简单问答
- `doubao-pro-4k` - 专业版，精度高，适合复杂推理
- `doubao-pro-32k` - 专业版长文本，支持更长输入

## 6. 验证配置

配置完成后，重新启动应用。在控制台输出中，你应该看到：

```
=== 智能答题助手配置信息 ===
豆包AI已配置: true
```

## 7. 费用说明

- 豆包AI为付费服务，请根据实际使用量付费
- 建议设置合理的使用限额
- 监控API调用次数和费用

## 8. 故障排除

### 问题1：API Key无效
**解决方案：**
- 检查API Key是否正确复制
- 确认API Key是否已激活
- 检查是否有使用限制

### 问题2：模型不可用
**解决方案：**
- 检查模型名称是否正确
- 确认账户是否有该模型的使用权限
- 尝试使用其他可用模型

### 问题3：网络连接错误
**解决方案：**
- 检查网络连接
- 确认API端点URL是否正确
- 检查防火墙设置

## 9. 安全建议

1. **不要将API Key提交到版本控制系统**
2. **定期轮换API Key**
3. **设置合理的API调用限制**
4. **监控异常使用**

## 10. 支持

如果遇到问题，可以：
- 查看火山引擎官方文档
- 联系火山引擎技术支持
- 在GitHub Issues中反馈问题 