// ignore_for_file: lines_longer_than_80_chars
// Regenerate with: flutterfire configure -y -p w4sylnder -i com.washslender.app
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web Firebase options are not configured');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyArlRXmwG8pooLlR6_WU4CYY3oIzyFAFss',
    appId: '1:1081621778280:android:0fb61d9b4a70228b7950dd',
    messagingSenderId: '1081621778280',
    projectId: 'w4sylnder',
    storageBucket: 'w4sylnder.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyArlRXmwG8pooLlR6_WU4CYY3oIzyFAFss',
    appId: '1:1081621778280:ios:0fb61d9b4a70228b7950e0',
    messagingSenderId: '1081621778280',
    projectId: 'w4sylnder',
    storageBucket: 'w4sylnder.firebasestorage.app',
    iosBundleId: 'com.washslender.app',
  );
}
