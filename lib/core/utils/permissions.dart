import 'package:permission_handler/permission_handler.dart';

Future<bool> checkMicPermission() async {
  final PermissionStatus checkPermissionStatus =
      await Permission.microphone.status;
  if (checkPermissionStatus.isDenied ||
      checkPermissionStatus.isPermanentlyDenied) {
    final PermissionStatus permissionRequest =
        await Permission.microphone.request();
    if (permissionRequest.isDenied || permissionRequest.isPermanentlyDenied) {
      return false;
    }
  }
  return true;
}
