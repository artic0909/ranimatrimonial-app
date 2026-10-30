import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ranimatrimonial_app/firebase_options.dart';
import 'package:ranimatrimonial_app/services/api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
}

class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Rani Matrimonial Alerts',
    description: 'Real-time notifications for connection and chat requests',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static bool _isInitialized = false;

  /// Callback when a user taps a push notification
  static void Function(Map<String, dynamic> data)? onNotificationClicked;

  /// Initialize Firebase & Local Notifications
  static Future<void> initialize({
    void Function(Map<String, dynamic> data)? onNotificationClick,
  }) async {
    if (_isInitialized) return;

    onNotificationClicked = onNotificationClick;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 1. Register background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Request OS-level permissions (Android 13+ & iOS)
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Enable foreground notification presentation options
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Initialize Flutter Local Notifications for foreground pop-up banner
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final data = jsonDecode(response.payload!) as Map<String, dynamic>;
              onNotificationClicked?.call(data);
            } catch (_) {}
          }
        },
      );

      // Create Android Notification Channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // 4. Foreground notification listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notif = message.notification;
        final android = message.notification?.android;

        if (notif != null) {
          _localNotifications.show(
            id: notif.hashCode,
            title: notif.title,
            body: notif.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                importance: Importance.max,
                priority: Priority.high,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                playSound: true,
                enableVibration: true,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: jsonEncode(message.data),
          );
        }
      });

      // 5. User taps notification while app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        onNotificationClicked?.call(message.data);
      });

      // 6. Check if app was opened directly from a terminated state notification
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        onNotificationClicked?.call(initialMessage.data);
      }

      // 7. Sync FCM Device token with Laravel backend
      await syncDeviceToken();

      // Listen for token refreshes
      // ignore: deprecated_member_use
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        syncDeviceToken(explicitToken: newToken);
      });

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('PushNotificationService initialization error: $e');
      }
    }
  }

  /// Sync device FCM token to Laravel backend
  static Future<void> syncDeviceToken({String? explicitToken}) async {
    try {
      // ignore: deprecated_member_use
      final token = explicitToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('🔥 [FCM Device Token]: $token');
        await ApiService.instance.saveFcmToken(token);
      }
    } catch (e) {
      debugPrint('FCM Token sync error: $e');
    }
  }
}
