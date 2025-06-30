/// 应用配置管理类
/// 
/// 用于管理API密钥、应用设置等配置信息
/// 在实际使用中，请将API密钥存储在安全的地方
class AppConfig {
  // ============ OCR服务配置 ============
  
  /// 阿里云市场OCR API配置
  /// 申请地址: https://market.aliyun.com/products/57124001/cmapi024968.html
  static const String alicloudMarketAppCode = 'e4f0cb685a46456d855f26545d3c7886';
  
  // ============ AI服务配置 ============
  
  /// OpenAI ChatGPT API配置
  /// 申请地址: https://platform.openai.com/api-keys
  static const String openaiApiKey = 'YOUR_OPENAI_API_KEY';
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String openaiModel = 'gpt-3.5-turbo';
  
  /// 百度文心一言API配置
  /// 申请地址: https://cloud.baidu.com/product/wenxinworkshop
  static const String baiduAiApiKey = 'YOUR_BAIDU_AI_API_KEY';
  static const String baiduAiSecretKey = 'YOUR_BAIDU_AI_SECRET_KEY';
  
  /// 字节跳动豆包AI配置
  /// 申请地址: https://www.volcengine.com/product/doubao
  static const String doubaoApiKey = '5ef82bea-e493-40bf-800b-17f336b503c9';
  static const String doubaoBaseUrl = 'https://ark.cn-beijing.volces.com/api/v3';
  static const String doubaoModel = 'doubao-1.5-pro-32k-250115'; // 使用示例中的模型
  
  // ============ 搜索服务配置 ============
  
  /// 百度搜索API密钥
  /// 申请地址: https://ai.baidu.com/tech/websearch
  static const String baiduSearchApiKey = 'YOUR_BAIDU_SEARCH_API_KEY';
  
  /// 必应搜索API密钥
  /// 申请地址: https://www.microsoft.com/en-us/bing/apis/bing-web-search-api
  static const String bingSearchApiKey = 'YOUR_BING_SEARCH_API_KEY';
  
  // ============ 应用配置 ============
  
  /// 应用环境
  static const bool isDebug = true;
  static const String appEnv = 'development'; // development/production
  
  /// 超时配置（秒）
  static const int ocrTimeout = 30;
  static const int aiTimeout = 15;
  static const int searchTimeout = 10;
  static const int httpTimeout = 30;
  
  /// 队列配置
  static const int maxScreenshotQueue = 10;
  static const int maxRetryAttempts = 3;
  
  /// 缓存配置
  static const int hiveCacheLimit = 1000;
  static const int databaseCacheSize = 500;
  
  // ============ UI配置 ============
  
  /// 显示配置
  static const int answerDisplayDuration = 10; // 秒
  static const double overlayOpacity = 0.9;
  static const bool notificationSound = true;
  static const bool vibrationEnabled = true;
  
  /// 主题配置
  static const bool darkModeDefault = false;
  static const String defaultFontFamily = 'PingFang';
  
  // ============ 安全配置 ============
  
  /// API限制配置
  static const int apiRateLimit = 60; // 请求/分钟
  static const int maxDailyRequests = 1000;
  
  /// 数据加密配置
  static const String encryptionKey = 'smart_quiz_helper_2024';
  static const bool encryptLocalData = true;
  
  // ============ 日志配置 ============
  
  /// 日志配置
  static const String logLevel = 'info'; // debug/info/warning/error
  static const int logRetentionDays = 7;
  static const bool uploadErrorLogs = false;
  static const int maxLogFileSize = 5 * 1024 * 1024; // 5MB
  
  // ============ 数据库配置 ============
  
  /// 数据库配置
  static const String localDbName = 'smart_quiz_helper.db';
  static const int dbVersion = 1;
  static const String questionsTableName = 'questions';
  static const String wrongQuestionsTableName = 'wrong_questions';
  
  // ============ 功能开关 ============
  
  /// 功能开关
  static const bool enableOcr = true;
  static const bool enableAiSearch = true;
  static const bool enableWebSearch = true;
  static const bool enableLocalSearch = true;
  static const bool enableDatabaseQuery = false; // 是否启用数据库查询（默认关闭，直接使用AI）
  // 说明：
  // - true: OCR解析后先查询本地题库，未找到答案再调用AI
  // - false: OCR解析后直接调用AI，跳过数据库查询（推荐，响应更快）
  static const bool enableAutoUpdate = true;
  static const bool enableAnalytics = false;
  
  // ============ 性能配置 ============
  
  /// 性能优化配置
  static const int imageMaxWidth = 1920;
  static const int imageMaxHeight = 1080;
  static const double imageQuality = 0.8;
  static const bool enableImageCompression = true;
  
  /// 内存管理
  static const int maxMemoryUsage = 100 * 1024 * 1024; // 100MB
  static const bool enableMemoryOptimization = true;
  
  // ============ 网络配置 ============
  
  /// 网络配置
  static const int connectTimeout = 10; // 秒
  static const int receiveTimeout = 30; // 秒
  static const int sendTimeout = 10; // 秒
  static const bool enableProxy = false;
  static const String proxyHost = '';
  static const int proxyPort = 0;
  
  // ============ 工具方法 ============
  
  /// 检查是否为生产环境
  static bool get isProduction => appEnv == 'production';
  
  /// 检查是否为开发环境
  static bool get isDevelopment => appEnv == 'development';
  
  /// 获取应用版本信息
  static String get appVersion => '1.0.0';
  static String get buildNumber => '1';
  
  /// 检查阿里云市场OCR是否已配置
  static bool get isAlicloudMarketOcrConfigured {
    return alicloudMarketAppCode != 'YOUR_ALICLOUD_MARKET_APPCODE' &&
           alicloudMarketAppCode.isNotEmpty;
  }
  
  /// 检查豆包AI是否已配置
  static bool get isDoubaoAiConfigured {
    return doubaoApiKey != 'YOUR_DOUBAO_API_KEY' &&
           doubaoApiKey.isNotEmpty;
  }
  
  /// 获取默认用户代理
  static String get userAgent => 'SmartQuizHelper/$appVersion';
  
  /// 配置验证
  static List<String> validateConfig() {
    final List<String> errors = [];
    
    // 检查阿里云市场OCR配置（必需）
    if (!isAlicloudMarketOcrConfigured) {
      errors.add('阿里云市场OCR AppCode未配置（必需）');
    }
    
    // 检查豆包AI配置（推荐但非必需）
    if (!isDoubaoAiConfigured) {
      errors.add('豆包AI未配置（推荐配置以获得AI答题功能）');
    }
    
    // 检查数据库查询配置（如果启用但没有AI备用方案的话）
    if (enableDatabaseQuery && !isDoubaoAiConfigured) {
      errors.add('启用了数据库查询但豆包AI未配置，可能无法处理新题目');
    }
    
    // 检查超时配置
    if (ocrTimeout <= 0) {
      errors.add('OCR超时时间配置无效');
    }
    
    if (aiTimeout <= 0) {
      errors.add('AI超时时间配置无效');
    }
    
    // 检查缓存配置
    if (hiveCacheLimit <= 0) {
      errors.add('缓存限制配置无效');
    }
    
    return errors;
  }
  
  /// 获取环境特定的配置
  static Map<String, dynamic> getEnvConfig() {
    return {
      'environment': appEnv,
      'debug': isDebug,
      'ocrConfigured': isAlicloudMarketOcrConfigured,
      'aiConfigured': isDoubaoAiConfigured,
      'databaseQueryEnabled': enableDatabaseQuery,
      'version': appVersion,
      'buildNumber': buildNumber,
    };
  }
  
  /// 打印配置信息（仅开发环境）
  static void printConfig() {
    if (!isDebug) return;
    
    print('=== 智能答题助手配置信息 ===');
    print('环境: $appEnv');
    print('版本: $appVersion ($buildNumber)');
    print('调试模式: $isDebug');
    print('OCR已配置: $isAlicloudMarketOcrConfigured');
    print('豆包AI已配置: $isDoubaoAiConfigured');
    print('OCR超时: ${ocrTimeout}秒');
    print('AI超时: ${aiTimeout}秒');
    print('搜索超时: ${searchTimeout}秒');
    print('缓存限制: $hiveCacheLimit');
    print('========================');
  }
} 