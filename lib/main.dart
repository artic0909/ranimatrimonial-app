import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';
import 'services/push_notification_service.dart';
import 'theme/rani_colors.dart';
import 'theme/rani_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API service and restore Sanctum session if available
  await ApiService.instance.init();

  // Initialize Firebase Cloud Messaging & OS-level Push Notification Service
  try {
    await PushNotificationService.initialize();
  } catch (_) {}

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: RaniColors.surfaceAlt,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const RaniMatrimonialApp());
}

class RaniMatrimonialApp extends StatelessWidget {
  const RaniMatrimonialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rani Matrimonial',
      debugShowCheckedModeBanner: false,
      theme: RaniTheme.light,
      home: const RaniSplashScreen(),
    );
  }
}
