import 'dart:html' as html;

class WebNotificationHelper {
  static Future<void> requestWebPermission() async {
    await html.Notification.requestPermission();
  }

  static void showWebNotification(String title, String body) {
    if (html.Notification.permission == 'granted') {
      html.Notification(title, body: body);
    }
  }
}