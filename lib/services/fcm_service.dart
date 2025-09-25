import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  /// Initialize FCM + Local Notifications
  /*Future<void> initialize() async {
    // Request permissions
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Got a message in foreground!');
      print('🔹 Message data: ${message.data}');
    });

    // Log the token when initialized
    final token = await _messaging.getToken();
    log("🔑 Initial FCM Token: $token");

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      log("♻️ FCM Token refreshed: $newToken");
    });

    log("✅ FCM Service initialized");
  }

  Future<String?> getToken() async {
    final token = await _messaging.getToken();
    log("🔑 getToken() called -> $token");
    return token;
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;




  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      channelDescription: 'Notification channel for chat messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? "New Message",
      message.notification?.body ?? "You received a new message",
      details,
      payload: message.data['chatRoomId'] ?? '',
    );
  }*/

  Future<void> initialize() async {

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      log(" Notification permissions not granted.");
      return;
    }

    log(" User granted notification permissions");

    /// iOS: Wait for APNs token
    if (Platform.isIOS) {
      String? apnsToken;
      int attempts = 0;
      const int maxAttempts = 10;

      do {
        apnsToken = await _messaging.getAPNSToken();
        await Future.delayed(const Duration(milliseconds: 300));
        attempts++;
      } while (apnsToken == null && attempts < maxAttempts);

      if (apnsToken == null) {
        log("Failed to get APNs token after $maxAttempts attempts.");
        return;
      }

      log("APNs Token: $apnsToken");
    }

    ///  Get FCM token
    final token = await _messaging.getToken();
    log("FCM Token: $token");

    /// Initialize local notifications
    await _initializeLocalNotifications();

    ///  Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("📥 Foreground message: ${message.notification?.title}");
      _showNotification(message);
    });

    ///  App opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("🔁 App opened from background notification");
      _navigateToScreen(message);
    });

    /// App opened from terminated state
    RemoteMessage? initialMessage =
    await _messaging.getInitialMessage();

    if (initialMessage != null) {
      log("App opened from terminated state notification");
      /*WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToScreen(initialMessage);
      });*/
    }
  }

  /// Setup local notification plugin
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      /*onDidReceiveNotificationResponse: (NotificationResponse response) {
        log(" Local notification clicked");
        _navigateToScreenFromLocal(response.payload);
      },*/
    );
  }

  /// Show local notification
  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'Your notification channel description',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    /*final payload = jsonEncode({
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'time': message.sentTime?.toIso8601String() ??
          DateTime.now().toIso8601String(),
    });*/

    await _localNotifications.show(
      0,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new message',
      notificationDetails,
     // payload: payload,
    );
  }

  /// Handle navigation for remote notifications
  void _navigateToScreen(RemoteMessage message) {
    final title = message.notification?.title ?? 'No Title';
    final body = message.notification?.body ?? 'No Body';
    final sentTime = message.sentTime?.toIso8601String() ?? DateTime.now().toIso8601String();

    log("Navigating to screen with:");
    log("Title: $title");
    log("Body: $body");
    log("Sent Time: $sentTime");

    /*navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => NotificationPage(
          title: title,
          body: body,
          time: sentTime,
        ),
      ),
    );*/
  }


  /// Handle local notification click
  /*void _navigateToScreenFromLocal(String? payload) {
    if (payload == null) {
      log("No payload found in local notification");
      return;
    }

    final data = jsonDecode(payload);
    final title = data['title'] ?? 'No Title';
    final body = data['body'] ?? 'No Body';
    final time = data['time'] ?? DateTime.now().toIso8601String();

    log("Navigating from local notification with:");
    log("Title: $title");
    log("Body: $body");
    log("Time: $time");

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => NotificationPage(
          title: title,
          body: body,
          time: time,
        ),
      ),
    );
  }*/

}


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("🌙 Background FCM: ${message.notification?.title} - ${message.notification?.body}");
  //await FcmService._showLocalNotification(message);
}
