import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service: App Privacy & Screenshot Proof Protection
/// Enforces hardware-level FLAG_SECURE on Android and secure layer/blur on iOS
/// to prevent taking screenshots, screen recordings, or leaking data in app switchers.
class SecurityService {
  static const MethodChannel _channel = MethodChannel('com.rani.matrimonial/security');
  static bool _isSecure = false;

  /// Whether screenshot and screen capture protection is currently enabled
  static bool get isSecure => _isSecure;

  /// Enable screenshot proofing & screen recording protection across post-login screens
  static Future<void> enableSecureScreen() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _channel.invokeMethod('enableSecureScreen');
        _isSecure = true;
        debugPrint('[SecurityService] Screenshot protection ENABLED');
      }
    } catch (e) {
      debugPrint('[SecurityService] Could not enable secure screen: $e');
    }
  }

  /// Disable screenshot proofing (e.g. for pre-login screens or when logging out)
  static Future<void> disableSecureScreen() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _channel.invokeMethod('disableSecureScreen');
        _isSecure = false;
        debugPrint('[SecurityService] Screenshot protection DISABLED');
      }
    } catch (e) {
      debugPrint('[SecurityService] Could not disable secure screen: $e');
    }
  }
}

