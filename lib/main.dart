import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/rani_colors.dart';
import 'theme/rani_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
