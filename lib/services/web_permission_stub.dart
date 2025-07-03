/// Web平台权限处理stub文件
/// 提供与permission_handler包兼容的接口，用于Web平台编译

class PermissionStatus {
  static const PermissionStatus granted = PermissionStatus._(true);
  static const PermissionStatus denied = PermissionStatus._(false);
  static const PermissionStatus restricted = PermissionStatus._(false);
  static const PermissionStatus limited = PermissionStatus._(false);
  static const PermissionStatus permanentlyDenied = PermissionStatus._(false);
  
  final bool isGranted;
  const PermissionStatus._(this.isGranted);
  
  bool operator ==(Object other) {
    return identical(this, other) || 
           (other is PermissionStatus && other.isGranted == isGranted);
  }
  
  @override
  int get hashCode => isGranted.hashCode;
}

class Permission {
  static const Permission storage = Permission._('storage');
  static const Permission notification = Permission._('notification');
  static const Permission systemAlertWindow = Permission._('systemAlertWindow');
  
  final String _name;
  const Permission._(this._name);
  
  Future<PermissionStatus> get status async {
    // Web平台默认授权
    return PermissionStatus.granted;
  }
  
  Future<PermissionStatus> request() async {
    // Web平台默认授权
    return PermissionStatus.granted;
  }
} 