class PermissionService {
  static Future<bool> requestMicrophonePermission() async {
    // Permissions are usually handled differently or assumed granted on some platforms/web
    return true;
  }
}
