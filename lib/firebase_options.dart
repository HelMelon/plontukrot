import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyC7PQ3dHpT7JDiiAXQfo1zdcAl_KLWz4is',
    appId: '1:577871492679:web:9ae1872d4d3d4951566362',
    messagingSenderId: '577871492679',
    projectId: 'plant-logger-e0677',
    authDomain: 'plant-logger-e0677.firebaseapp.com',
    storageBucket: 'plant-logger-e0677.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAjaUEZPrgZMyM_615ddr6yr8WIMlcB_hE',
    appId: '1:577871492679:android:e4bbb5e19ffa095e566362',
    messagingSenderId: '577871492679',
    projectId: 'plant-logger-e0677',
    storageBucket: 'plant-logger-e0677.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCqYdMPqVeKaHkFsXts_S708X5OU8pSyyg',
    appId: '1:577871492679:ios:dffbd79ef2a93825566362',
    messagingSenderId: '577871492679',
    projectId: 'plant-logger-e0677',
    storageBucket: 'plant-logger-e0677.firebasestorage.app',
    androidClientId:
        '577871492679-757g3gcj9seo4nsb7ve1h06ia3tjqf35.apps.googleusercontent.com',
    iosClientId:
        '577871492679-9ps3ooddbjmelthlc3a9d2gkh6ra49rn.apps.googleusercontent.com',
    iosBundleId: 'com.example.plontukrot',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCqYdMPqVeKaHkFsXts_S708X5OU8pSyyg',
    appId: '1:577871492679:ios:dffbd79ef2a93825566362',
    messagingSenderId: '577871492679',
    projectId: 'plant-logger-e0677',
    storageBucket: 'plant-logger-e0677.firebasestorage.app',
    androidClientId:
        '577871492679-757g3gcj9seo4nsb7ve1h06ia3tjqf35.apps.googleusercontent.com',
    iosClientId:
        '577871492679-9ps3ooddbjmelthlc3a9d2gkh6ra49rn.apps.googleusercontent.com',
    iosBundleId: 'com.example.plontukrot',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC7PQ3dHpT7JDiiAXQfo1zdcAl_KLWz4is',
    appId: '1:577871492679:web:055f2744a07cc60f566362',
    messagingSenderId: '577871492679',
    projectId: 'plant-logger-e0677',
    authDomain: 'plant-logger-e0677.firebaseapp.com',
    storageBucket: 'plant-logger-e0677.firebasestorage.app',
  );
}
