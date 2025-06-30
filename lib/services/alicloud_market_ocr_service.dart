import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/config.dart';

/// 阿里云市场OCR服务
/// 基于阿里云市场API实现文字识别功能
class AlicloudMarketOcrService {
  static final AlicloudMarketOcrService _instance = AlicloudMarketOcrService._internal();
  factory AlicloudMarketOcrService() => _instance;
  AlicloudMarketOcrService._internal();

  late final Dio _dio;
  
  // 阿里云市场OCR API配置
  static const String _host = 'https://gjbsb.market.alicloudapi.com';
  static const String _path = '/ocrservice/advanced';
  
  /// 初始化服务
  void initialize() {
    _dio = Dio(BaseOptions(
      connectTimeout: Duration(seconds: AppConfig.httpTimeout),
      receiveTimeout: Duration(seconds: AppConfig.ocrTimeout),
      sendTimeout: Duration(seconds: AppConfig.httpTimeout),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'User-Agent': AppConfig.userAgent,
      },
    ));

    if (AppConfig.isDebug) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false, // 不打印请求体（图片数据太大）
        responseBody: true,
      ));
    }
  }

  /// 通用文字识别
  /// [imageBytes] 图片字节数据
  /// [prob] 是否返回置信度
  /// [charInfo] 是否返回字符信息
  /// [rotate] 是否支持旋转识别
  /// [table] 是否识别表格
  Future<AlicloudMarketOcrResult> recognizeText(
    Uint8List imageBytes, {
    bool prob = true,
    bool charInfo = true,
    bool rotate = true,
    bool table = false,
    String? imageUrl,
  }) async {
    try {
      print('🌐 开始阿里云市场OCR识别...');

      // 检查配置
      if (!_isConfigured()) {
        throw Exception('阿里云市场OCR配置未完成，请检查AppCode配置');
      }

      // 准备请求数据
      String imageBase64 = '';
      String url = '';
      
      if (imageUrl != null && imageUrl.isNotEmpty) {
        url = imageUrl;
      } else {
        imageBase64 = base64Encode(imageBytes);
      }
      
      final Map<String, dynamic> requestBody = {
        'img': imageBase64,
        'url': url,
        'prob': prob,
        'charInfo': charInfo,
        'rotate': rotate,
        'table': table,
      };

      // 设置认证头
      final headers = {
        'Authorization': 'APPCODE ${AppConfig.alicloudMarketAppCode}',
        'Content-Type': 'application/json; charset=UTF-8',
      };

      print('📤 发送OCR请求...');
      
      // 发送请求
      final response = await _dio.post(
        '$_host$_path',
        data: jsonEncode(requestBody),
        options: Options(headers: headers),
      );

      return _parseResponse(response.data);

    } catch (e) {
      print('❌ 阿里云市场OCR识别失败: $e');
      return AlicloudMarketOcrResult.error('识别失败: $e');
    }
  }

  /// 解析API响应
  AlicloudMarketOcrResult _parseResponse(dynamic data) {
    try {
      if (data == null) {
        return AlicloudMarketOcrResult.error('响应数据为空');
      }

      Map<String, dynamic> responseData;
      if (data is String) {
        responseData = jsonDecode(data);
      } else {
        responseData = data as Map<String, dynamic>;
      }

      // 检查是否有错误
      if (responseData['success'] == false) {
        final errorMsg = responseData['message'] ?? responseData['error_message'] ?? '未知错误';
        return AlicloudMarketOcrResult.error('API错误: $errorMsg');
      }

      // 检查状态码
      final code = responseData['code'] ?? responseData['status'];
      if (code != null && code != 200 && code != '200') {
        final errorMsg = responseData['message'] ?? '请求失败';
        return AlicloudMarketOcrResult.error('状态码错误($code): $errorMsg');
      }

      // 解析识别结果
      final List<String> lines = [];
      final StringBuffer fullText = StringBuffer();
      double confidence = 0.0;
      int wordCount = 0;

      // 尝试多种数据结构解析
      dynamic resultData = responseData['ret'] ?? 
                          responseData['data'] ?? 
                          responseData['result'] ?? 
                          responseData;

      if (resultData is List) {
        // 处理数组格式的结果
        for (final item in resultData) {
          if (item is Map<String, dynamic>) {
            final text = item['word'] ?? item['text'] ?? item['content'];
            final prob = item['prob'] ?? item['confidence'];
            
            if (text != null && text.toString().trim().isNotEmpty) {
              lines.add(text.toString().trim());
              fullText.writeln(text.toString().trim());
              wordCount++;
              
              if (prob != null) {
                confidence += (prob as num).toDouble();
              }
            }
          } else if (item is String && item.trim().isNotEmpty) {
            lines.add(item.trim());
            fullText.writeln(item.trim());
            wordCount++;
          }
        }
      } else if (resultData is Map<String, dynamic>) {
        // 处理对象格式的结果
        final content = resultData['content'] ?? resultData['text'] ?? resultData['word'];
        if (content != null) {
          final text = content.toString().trim();
          if (text.isNotEmpty) {
            lines.addAll(text.split('\n').where((line) => line.trim().isNotEmpty));
            fullText.write(text);
            wordCount = lines.length;
          }
        }
        
        // 尝试获取置信度
        final prob = resultData['prob'] ?? resultData['confidence'];
        if (prob != null) {
          confidence = (prob as num).toDouble();
        }
      } else if (resultData is String) {
        // 处理字符串格式的结果
        final text = resultData.trim();
        if (text.isNotEmpty) {
          lines.addAll(text.split('\n').where((line) => line.trim().isNotEmpty));
          fullText.write(text);
          wordCount = lines.length;
        }
      }

      // 计算平均置信度
      if (wordCount > 0 && confidence > 0) {
        confidence = confidence / wordCount;
      } else {
        confidence = 0.8; // 默认置信度
      }

      // 确保置信度在0-1范围内
      confidence = confidence.clamp(0.0, 1.0);

      final result = AlicloudMarketOcrResult(
        success: true,
        fullText: fullText.toString().trim(),
        lines: lines,
        confidence: confidence,
        wordCount: wordCount,
        rawData: responseData,
      );

      print('✅ 阿里云市场OCR识别完成，共识别 ${lines.length} 行文本，置信度: ${(confidence * 100).toStringAsFixed(1)}%');
      
      return result;

    } catch (e) {
      print('❌ 解析响应失败: $e');
      return AlicloudMarketOcrResult.error('解析响应失败: $e');
    }
  }

  /// 检查配置是否完整
  bool _isConfigured() {
    return AppConfig.alicloudMarketAppCode != 'YOUR_ALICLOUD_MARKET_APPCODE' &&
           AppConfig.alicloudMarketAppCode.isNotEmpty;
  }

  /// 获取服务状态
  Map<String, dynamic> getStatus() {
    return {
      'configured': _isConfigured(),
      'appCode': _isConfigured() ? '已配置' : '未配置',
      'host': _host,
      'path': _path,
    };
  }

  /// 释放资源
  void dispose() {
    _dio.close();
  }
}

/// 阿里云市场OCR识别结果
class AlicloudMarketOcrResult {
  final bool success;
  final String fullText;
  final List<String> lines;
  final double confidence;
  final String? error;
  final int wordCount;
  final Map<String, dynamic>? rawData;

  AlicloudMarketOcrResult({
    required this.success,
    this.fullText = '',
    this.lines = const [],
    this.confidence = 0.0,
    this.error,
    this.wordCount = 0,
    this.rawData,
  });

  factory AlicloudMarketOcrResult.error(String error) {
    return AlicloudMarketOcrResult(
      success: false,
      error: error,
    );
  }

  @override
  String toString() {
    return 'AlicloudMarketOcrResult(success: $success, fullText: ${fullText.length} chars, confidence: $confidence, error: $error)';
  }
} 