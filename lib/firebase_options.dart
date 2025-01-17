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
    apiKey: 'AIzaSyAhw6nxMh6Q6XdXG8PI90oaFRcFIVAh7KM',
    appId: '1:290377538786:web:0cefd0500df95758a652bb',
    messagingSenderId: '290377538786',
    projectId: 'st-annuarite',
    authDomain: 'st-annuarite.firebaseapp.com',
    storageBucket: 'st-annuarite.appspot.com',
    measurementId: 'G-800QSDVV46',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDPQ0hkqgqE-4d8LmuJpV4muw_FyKDnlZo',
    appId: '1:290377538786:android:2fc1cf6c395f02afa652bb',
    messagingSenderId: '290377538786',
    projectId: 'st-annuarite',
    storageBucket: 'st-annuarite.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD574DU2MIu5dySS8cPGfnmknIueemfnu8',
    appId: '1:290377538786:ios:b0e54142c4877f7ea652bb',
    messagingSenderId: '290377538786',
    projectId: 'st-annuarite',
    storageBucket: 'st-annuarite.appspot.com',
    iosBundleId: 'com.example.ccm',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD574DU2MIu5dySS8cPGfnmknIueemfnu8',
    appId: '1:290377538786:ios:b0e54142c4877f7ea652bb',
    messagingSenderId: '290377538786',
    projectId: 'st-annuarite',
    storageBucket: 'st-annuarite.appspot.com',
    iosBundleId: 'com.example.ccm',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAhw6nxMh6Q6XdXG8PI90oaFRcFIVAh7KM',
    appId: '1:290377538786:web:c9a276c558ca587ca652bb',
    messagingSenderId: '290377538786',
    projectId: 'st-annuarite',
    authDomain: 'st-annuarite.firebaseapp.com',
    storageBucket: 'st-annuarite.appspot.com',
    measurementId: 'G-WMB8NY564T',
  );
}
