/// Web平台File处理stub文件
/// 提供与dart:io File兼容的接口，用于Web平台编译

import 'dart:typed_data';

class File {
  final String path;
  
  File(this.path);
  
  Future<bool> exists() async {
    // Web平台默认返回false
    return false;
  }
  
  Future<void> delete() async {
    // Web平台不支持文件删除，这里是空实现
  }
  
  Future<Uint8List> readAsBytes() async {
    // Web平台不支持文件读取，返回空数据
    return Uint8List(0);
  }
  
  Future<void> writeAsBytes(List<int> bytes) async {
    // Web平台不支持文件写入，这里是空实现
  }
} 