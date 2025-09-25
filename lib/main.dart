import 'dart:developer';
import 'dart:io';

import 'package:chat_application/core/constants/app_color.dart';
import 'package:chat_application/firebase_options.dart';
import 'package:chat_application/services/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeFCM();
  await FcmService().initialize();
  runApp(const ProviderScope(child: ChatApp()));
}

Future<void> initializeFCM() async {
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (Platform.isIOS) {
      String? apnsToken;
      int attempts = 0;
      const int maxAttempts = 10;

      do {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        await Future.delayed(const Duration(milliseconds: 300));
        attempts++;
      } while (apnsToken == null && attempts < maxAttempts);

      log("APNS Token: $apnsToken");
    }

    String? token = await FirebaseMessaging.instance.getToken();
    log("FCM Token: $token");
  } catch (e) {
    debugPrint('FCM initialization error: $e');
  }
}

class ChatApp extends ConsumerWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Flutter Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
