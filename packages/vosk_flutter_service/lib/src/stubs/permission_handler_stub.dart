enum PermissionStatus {
  denied,
  granted,
  restricted,
  limited,
  permanentlyDenied,
  provisional,
}

extension PermissionStatusGetters on PermissionStatus {
  bool get isGranted => this == PermissionStatus.granted;
  bool get isDenied => this == PermissionStatus.denied;
}

class Permission {
  static const microphone = Permission._();
  const Permission._();
  Future<PermissionStatus> get status async => PermissionStatus.denied;
  Future<PermissionStatus> request() async => PermissionStatus.denied;
}
