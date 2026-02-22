// File generated. To regenerate, run `flutterfire configure`.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDTFHx8jKrkeXCwtGeBDQV29phYd2e_UdM',
    appId: '1:668916133955:web:agrosmart',
    messagingSenderId: '668916133955',
    projectId: 'agro-smart-2026',
    authDomain: 'agro-smart-2026.firebaseapp.com',
    databaseURL: 'https://agro-smart-2026-default-rtdb.firebaseio.com',
    storageBucket: 'agro-smart-2026.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDTFHx8jKrkeXCwtGeBDQV29phYd2e_UdM',
    appId: '1:668916133955:android:agrosmart',
    messagingSenderId: '668916133955',
    projectId: 'agro-smart-2026',
    databaseURL: 'https://agro-smart-2026-default-rtdb.firebaseio.com',
    storageBucket: 'agro-smart-2026.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDTFHx8jKrkeXCwtGeBDQV29phYd2e_UdM',
    appId: '1:668916133955:ios:agrosmart',
    messagingSenderId: '668916133955',
    projectId: 'agro-smart-2026',
    databaseURL: 'https://agro-smart-2026-default-rtdb.firebaseio.com',
    storageBucket: 'agro-smart-2026.firebasestorage.app',
    iosClientId: 'com.agrosmart.app',
    iosBundleId: 'com.agrosmart.app',
  );
}
