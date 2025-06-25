// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyByJavF0pDsU_GdQgjGXYR0iHLTKXBOd9k',
    appId: '1:426462153394:web:3fb635fbb74f39abf697ab',
    messagingSenderId: '426462153394',
    projectId: 'lagu-advent',
    authDomain: 'lagu-advent.firebaseapp.com',
    databaseURL:
        'https://lagu-advent-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'lagu-advent.firebasestorage.app',
    measurementId: 'G-5BXNPJFML2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: '426462153394',
    projectId: 'lagu-advent',
    databaseURL:
        'https://lagu-advent-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'lagu-advent.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '426462153394',
    projectId: 'lagu-advent',
    databaseURL:
        'https://lagu-advent-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'lagu-advent.firebasestorage.app',
    iosBundleId: 'com.example.yourapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: '426462153394',
    projectId: 'lagu-advent',
    databaseURL:
        'https://lagu-advent-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'lagu-advent.firebasestorage.app',
    iosBundleId: 'com.example.yourapp',
  );
}
