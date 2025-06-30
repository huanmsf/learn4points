/// 配置示例文件
/// 
/// 这个文件展示了如何正确配置阿里云市场OCR API
/// 请复制以下配置到 lib/utils/config.dart 中

// ============ 阿里云市场OCR配置示例 ============

/// 阿里云市场OCR API配置（必需）
/// 申请地址: https://market.aliyun.com/products/57124001/cmapi024968.html
static const String alicloudMarketAppCode = 'YOUR_ALICLOUD_MARKET_APPCODE';    // 替换为您的AppCode

/// 字节跳动豆包AI配置（推荐）
/// 申请地址: https://www.volcengine.com/product/doubao
/// 配置指南: 请查看 豆包AI配置指南.md
static const String doubaoApiKey = 'YOUR_DOUBAO_API_KEY';                     // 替换为您的API Key
static const String doubaoBaseUrl = 'https://ark.cn-beijing.volces.com/api/v3';
static const String doubaoModel = 'doubao-lite-32k';

// ============ 完整配置示例 ============

/*
/// 阿里云市场OCR API配置
static const String alicloudMarketAppCode = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

/// 字节跳动豆包AI配置
static const String doubaoApiKey = 'sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
static const String doubaoBaseUrl = 'https://ark.cn-beijing.volces.com/api/v3';
static const String doubaoModel = 'doubao-lite-32k';
*/

// ============ 配置验证 ============

/*
配置完成后，启动应用时会看到以下日志：

=== 智能答题助手配置信息 ===
OCR已配置: true
豆包AI已配置: true
✅ OCR服务初始化成功，当前提供商: alicloudMarket
🌐 使用阿里云市场OCR服务

如果配置错误，会看到：
❌ 阿里云市场OCR未配置！请在config.dart中设置alicloudMarketAppCode
⚠️ 豆包AI未配置，请在lib/utils/config.dart中设置doubaoApiKey
*/

// ============ 使用方法 ============

/*
1. 配置阿里云市场OCR服务（必需）：
   a) 购买服务：https://market.aliyun.com/products/57124001/cmapi024968.html
   b) 获取AppCode：进入阿里云控制台 > API市场 > 查看AppCode
   c) 配置应用：将AppCode填入config.dart中的alicloudMarketAppCode

2. 配置豆包AI服务（推荐）：
   a) 申请账户：https://www.volcengine.com/product/doubao
   b) 获取API Key：在火山引擎控制台创建应用并获取API Key
   c) 配置应用：将API Key填入config.dart中的doubaoApiKey
   d) 详细指南：请参考 豆包AI配置指南.md

3. 验证配置：
   启动应用，查看控制台日志确认配置成功
*/

// ============ 重要提醒 ============

/*
阿里云市场OCR注意事项：
- AppCode格式类似：xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx（32位字符）
- 请妥善保管AppCode，不要泄露给他人
- 注意API调用次数限制，避免超量使用

豆包AI注意事项：
- API Key格式类似：sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 豆包AI为付费服务，请监控使用量和费用
- 请妥善保管API Key，不要提交到版本控制系统
- 如配置错误，系统会自动跳过AI查询，仅使用本地题库

如有问题，请参考：
- 阿里云市场帮助文档
- 豆包AI配置指南.md
- 火山引擎官方文档
*/ 