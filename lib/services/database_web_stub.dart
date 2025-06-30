/// Web平台数据库处理stub文件
/// 提供与sqflite包兼容的接口，用于Web平台编译

class Database {
  Future<void> insert(String table, Map<String, dynamic> data, {ConflictAlgorithm? conflictAlgorithm}) async {
    // Web平台不支持SQLite，这里是空实现
  }
  
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, int? limit}) async {
    // Web平台不支持SQLite，返回空列表
    return [];
  }
  
  Future<void> update(String table, Map<String, dynamic> data, {String? where, List<dynamic>? whereArgs}) async {
    // Web平台不支持SQLite，这里是空实现
  }
  
  Future<void> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    // Web平台不支持SQLite，这里是空实现
  }
  
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? args]) async {
    // Web平台不支持SQLite，返回空列表
    return [];
  }
  
  Future<void> execute(String sql) async {
    // Web平台不支持SQLite，这里是空实现
  }
  
  Future<void> close() async {
    // Web平台不支持SQLite，这里是空实现
  }
}

enum ConflictAlgorithm {
  replace,
  ignore,
  fail,
  abort,
  rollback,
}

Future<String> getDatabasesPath() async {
  // Web平台返回空路径
  return '';
}

Future<Database> openDatabase(
  String path, {
  int? version,
  void Function(Database, int)? onCreate,
  void Function(Database, int, int)? onUpgrade,
}) async {
  // Web平台返回空的Database实例
  return Database();
} 