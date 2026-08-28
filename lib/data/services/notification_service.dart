import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// فلاتر بتختار الملف الصح بناءً على المنصة تلقائياً
import 'mobile_notification.dart'
    if (dart.library.html) 'web_notification.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [BG] FCM message received');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _initialized = false;

  /// دالة التشغيل: مش بنعمل await للـ setup عشان الـ Loading ميعلقش
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;
    _initialized = true;

    // بنشغل الإعدادات في الخلفية عشان الـ UI يفضل شغال
    _setupNotificationsAsync(navigatorKey);
    
    debugPrint('✅ NotificationService initialized (Background process started)');
  }

  /// دالة الإعداد الكامل في الخلفية
  Future<void> _setupNotificationsAsync(GlobalKey<NavigatorState> navigatorKey) async {
    try {
      await _requestPermissions();
      _registerForegroundListener(navigatorKey);
      _registerOnMessageOpenedApp(navigatorKey);
      await _handleInitialMessage(navigatorKey);
    } catch (e) {
      debugPrint('❌ Notification Setup Error: $e');
    }
  }

  // Future<String?> getToken() async {
  //   try {
  //     if (kIsWeb) {
  //       // في الويب بنستخدم الـ VAPID Key
  //       return await _fcm.getToken(
  //         vapidKey: "BJLgOhARl5qk42pA1ho29DtJrKKLdLlSWmdhzqkw85pBsUEwcmu9DvMMJh2aXb4F3iLWxKLPq5He_Y0F8RaxFHU",
  //       );
  //     }
  //     return await _fcm.getToken();
  //   } catch (e) {
  //     debugPrint('❌ Token Error: $e');
  //     return null;
  //   }
  // }


  Future<String?> getToken() async {
    try {
      // 1. لازم نطلب إذن الأول عشان الأبلكيشن ميهنجش
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('⚠️ User declined or has not accepted permission');
        return null;
      }

      // 2. محاولة جلب التوكن مع Timeout عشان لو علق ميوقتش الأبلكيشن
      String? token;
      if (kIsWeb) {
        token = await _fcm.getToken(
          vapidKey: "BJLgOhARl5qk42pA1ho29DtJrKKLdLlSWmdhzqkw85pBsUEwcmu9DvMMJh2aXb4F3iLWxKLPq5He_Y0F8RaxFHU",
        ).timeout(const Duration(seconds: 10)); // لو خد أكتر من 10 ثواني كنسل
      } else {
        token = await _fcm.getToken().timeout(const Duration(seconds: 10));
      }

      debugPrint('🚀 FCM Token: $token');
      return token;
    } catch (e) {
      // 3. أهم حاجة هنا: بنطبع الخطأ بس بنرجع null عشان الأبلكيشن يكمل الـ Boot
      debugPrint('❌ FCM Token Error (Handled): $e');
      return null;
    }
  }

  /// دالة متابعة تحديث التوكن (مهمة للـ AuthProvider)
  void onTokenRefresh(void Function(String token) onRefresh) {
    if (kIsWeb) return;
    _fcm.onTokenRefresh.listen(onRefresh);
  }

  Future<void> _requestPermissions() async {
    try {
      // بنحط timeout عشان لو المتصفح علق البرنامج ميفضلش واقف
      await _fcm.requestPermission(
        alert: true, 
        badge: true, 
        sound: true,
      ).timeout(const Duration(seconds: 8));

      if (kIsWeb) {
        await WebNotificationHelper.requestWebPermission();
      }
    } catch (e) {
      debugPrint('🔔 Permission request timed out or failed: $e');
    }
  }

  void _registerForegroundListener(GlobalKey<NavigatorState> navigatorKey) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Dealio';
      final body = message.notification?.body ?? '';

      if (kIsWeb) {
        WebNotificationHelper.showWebNotification(title, body);
      }
      _showInAppSnackBar(title, body, navigatorKey);
    });
  }

  void _registerOnMessageOpenedApp(GlobalKey<NavigatorState> navigatorKey) {
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) => _routeFromMessage(message.data, navigatorKey),
    );
  }

  Future<void> _handleInitialMessage(GlobalKey<NavigatorState> navigatorKey) async {
    final message = await _fcm.getInitialMessage();
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _routeFromMessage(message.data, navigatorKey),
      );
    }
  }

  void _routeFromMessage(Map<String, dynamic> data, GlobalKey<NavigatorState> navigatorKey) {
    final type = data['type']?.toString();
    final orderId = data['orderId']?.toString();
    if (type == 'order_status' && orderId != null) {
      navigatorKey.currentState?.pushNamed(
        '/order-detail',
        arguments: {'orderId': orderId},
      );
    }
  }

  void _showInAppSnackBar(String title, String body, GlobalKey<NavigatorState> navigatorKey) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF1E1E2E),
        content: Text(
          "$title: $body",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}