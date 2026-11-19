import 'package:flutter/services.dart';

/// Read once from the installed Android package, not the source version string.
class InstalledAppVersion {
  static const channel = MethodChannel('app.iccardreader/app_info');
  static final Future<String?> current = read();

  static Future<String?> read() async {
    try {
      return await channel.invokeMethod<String>('installedVersion');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
