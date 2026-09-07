import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  static Future<String?> getDeviceMetadata() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        final browserName = _parseBrowserName(webInfo.browserName.name);
        final osName = _parseWebOS(webInfo.userAgent ?? webInfo.appVersion ?? '');
        return 'Platform: Web — $browserName on $osName';
      } else {
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await _deviceInfoPlugin.androidInfo;
          final manufacturer = androidInfo.manufacturer;
          final model = androidInfo.model;
          if (model.isNotEmpty) {
            String prefix = '';
            if (manufacturer.isNotEmpty) {
              final formattedManufacturer =
                  manufacturer[0].toUpperCase() + manufacturer.substring(1);
              if (!model.toLowerCase().startsWith(manufacturer.toLowerCase())) {
                prefix = '$formattedManufacturer ';
              }
            }
            return 'Device: Android — $prefix$model';
          }
          return 'Device: Android';
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await _deviceInfoPlugin.iosInfo;
          final model = iosInfo.model;
          return 'Device: ${model.isNotEmpty ? model : "iPhone"}';
        } else if (defaultTargetPlatform == TargetPlatform.windows) {
          final windowsInfo = await _deviceInfoPlugin.windowsInfo;
          final major = windowsInfo.majorVersion;
          if (major == 10) {
             final build = windowsInfo.buildNumber;
             // Windows 11 starts at build 22000
             if (build >= 22000) {
               return 'Device: Windows 11';
             }
             return 'Device: Windows 10';
          }
          return 'Device: Windows';
        } else if (defaultTargetPlatform == TargetPlatform.macOS) {
          return 'Device: macOS';
        } else if (defaultTargetPlatform == TargetPlatform.linux) {
          return 'Device: Linux';
        }
      }
    } catch (e) {
      debugPrint('Failed to get device info: $e');
    }
    return null;
  }

  static String _parseBrowserName(String? browserName) {
    if (browserName == null) return 'Unknown Browser';
    switch (browserName.toLowerCase()) {
      case 'chrome': return 'Chrome';
      case 'firefox': return 'Firefox';
      case 'safari': return 'Safari';
      case 'edge': return 'Edge';
      case 'opera': return 'Opera';
      case 'samsunginternet': return 'Samsung Internet';
      default: return 'Web Browser';
    }
  }

  static String _parseWebOS(String ua) {
    if (ua.isEmpty) return 'Unknown OS';
    ua = ua.toLowerCase();
    if (ua.contains('windows nt 10.0')) return 'Windows 10/11';
    if (ua.contains('windows nt 6.3')) return 'Windows 8.1';
    if (ua.contains('windows nt 6.2')) return 'Windows 8';
    if (ua.contains('windows nt 6.1')) return 'Windows 7';
    if (ua.contains('windows')) return 'Windows';

    if (ua.contains('mac os x')) return 'macOS';
    if (ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod')) return 'iOS';
    if (ua.contains('android')) return 'Android';

    if (ua.contains('ubuntu')) return 'Ubuntu Linux';
    if (ua.contains('fedora')) return 'Fedora Linux';
    if (ua.contains('linux')) return 'Linux';

    return 'Unknown OS';
  }
}

