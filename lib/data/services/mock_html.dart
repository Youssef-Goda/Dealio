// ignore_for_file: camel_case_types
class window {
  static _Notification Notification = _Notification();
}

class _Notification {
  String permission = 'denied';
  Future<String> requestPermission() async => 'denied';
  void call(String title, {String? body}) {}
}

class Notification {
  static String permission = 'denied';
  static Future<String> requestPermission() async => 'denied';
  Notification(String title, {String? body});
}