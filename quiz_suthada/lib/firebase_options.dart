// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return windows;
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
    apiKey: 'AIzaSyCvO8G2xw6KaM-rNm9TSWpXdVOBuitzDZ8',
    appId: '1:1057951291186:web:0c7ac0adde5b283fa1e92b',
    messagingSenderId: '1057951291186',
    projectId: 'income-expenses-a02da',
    authDomain: 'income-expenses-a02da.firebaseapp.com',
    storageBucket: 'income-expenses-a02da.appspot.com',
    measurementId: 'G-3TRXRFQWTQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCy7gZUh23wVReyhtEfrxMhPofx4Cd95V4',
    appId: '1:1057951291186:android:b865c3c821811720a1e92b',
    messagingSenderId: '1057951291186',
    projectId: 'income-expenses-a02da',
    storageBucket: 'income-expenses-a02da.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAH5ATRQ0-rQ30UC8PzdUO44qQg6VINzeM',
    appId: '1:1057951291186:ios:a09885a024113b6ca1e92b',
    messagingSenderId: '1057951291186',
    projectId: 'income-expenses-a02da',
    storageBucket: 'income-expenses-a02da.appspot.com',
    iosBundleId: 'com.example.quizSuthada',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAH5ATRQ0-rQ30UC8PzdUO44qQg6VINzeM',
    appId: '1:1057951291186:ios:a09885a024113b6ca1e92b',
    messagingSenderId: '1057951291186',
    projectId: 'income-expenses-a02da',
    storageBucket: 'income-expenses-a02da.appspot.com',
    iosBundleId: 'com.example.quizSuthada',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCvO8G2xw6KaM-rNm9TSWpXdVOBuitzDZ8',
    appId: '1:1057951291186:web:41b3e821077c0f39a1e92b',
    messagingSenderId: '1057951291186',
    projectId: 'income-expenses-a02da',
    authDomain: 'income-expenses-a02da.firebaseapp.com',
    storageBucket: 'income-expenses-a02da.appspot.com',
    measurementId: 'G-1EHK4W4RY5',
  );
}
