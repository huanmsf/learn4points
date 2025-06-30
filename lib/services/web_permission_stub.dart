/// Web平台权限处理stub文件
/// 提供与permission_handler包兼容的接口，用于Web平台编译

class PermissionStatus {
  final bool isGranted;
  PermissionStatus(this.isGranted);
}

class Permission {
  static const Permission storage = Permission._('storage');
  static const Permission notification = Permission._('notification');
  static const Permission systemAlertWindow = Permission._('systemAlertWindow');
  
  final String _name;
  const Permission._(this._name);
  
  Future<PermissionStatus> get status async {
    // Web平台默认授权
    return PermissionStatus(true);
  }
  
  Future<PermissionStatus> request() async {
    // Web平台默认授权
    return PermissionStatus(true);
  }
} 