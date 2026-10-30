// File generated for Rani Matrimonial.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBFv4AseLZwv0aBWuY6NrjO-lQmiXdUYDo',
    appId: '1:367518152017:android:21cae58ae1d36f6f940f70',
    messagingSenderId: '367518152017',
    projectId: 'rani-matrimonial',
    storageBucket: 'rani-matrimonial.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBFv4AseLZwv0aBWuY6NrjO-lQmiXdUYDo',
    appId: '1:367518152017:ios:21cae58ae1d36f6f940f70',
    messagingSenderId: '367518152017',
    projectId: 'rani-matrimonial',
    storageBucket: 'rani-matrimonial.firebasestorage.app',
    iosBundleId: 'com.rani.matrimonial',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBFv4AseLZwv0aBWuY6NrjO-lQmiXdUYDo',
    appId: '1:367518152017:ios:21cae58ae1d36f6f940f70',
    messagingSenderId: '367518152017',
    projectId: 'rani-matrimonial',
    storageBucket: 'rani-matrimonial.firebasestorage.app',
    iosBundleId: 'com.rani.matrimonial',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBFv4AseLZwv0aBWuY6NrjO-lQmiXdUYDo',
    appId: '1:367518152017:web:21cae58ae1d36f6f940f70',
    messagingSenderId: '367518152017',
    projectId: 'rani-matrimonial',
    storageBucket: 'rani-matrimonial.firebasestorage.app',
  );
}

