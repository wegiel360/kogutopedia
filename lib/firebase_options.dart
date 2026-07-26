import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return windows;
    }
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC7JAiMwFMphLd_ZOY0Jzqsr8NGKvSD3KQ',
    appId: '1:384110007427:android:e5c5a40fa48368061777b6',
    messagingSenderId: '384110007427',
    projectId: 'kogutopedia',
    storageBucket: 'kogutopedia.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBsfKPrCXZmv6K3wktl3cevvJ3b0acRGgA',
    appId: '1:384110007427:web:9cbb46e7f48a06931777b6',
    messagingSenderId: '384110007427',
    projectId: 'kogutopedia',
    authDomain: 'kogutopedia.firebaseapp.com',
    storageBucket: 'kogutopedia.firebasestorage.app',
  );
}
