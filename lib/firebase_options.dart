import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// THIS IS A PLACEHOLDER. You need to configure Firebase via `flutterfire configure`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Return dummy options so the app compiles. 
    // It will throw an exception if actually used without real configuration.
    return const FirebaseOptions(
      apiKey: 'DUMMY_API_KEY',
      appId: 'DUMMY_APP_ID',
      messagingSenderId: 'DUMMY_MESSAGING_SENDER_ID',
      projectId: 'DUMMY_PROJECT_ID',
    );
  }
}
