import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'firebase_options.dart';

/// Firebase'i başlatır ve gerekiyorsa Auth emülatörüne bağlar.
Future<void> initFirebase() async {
  await Firebase.initializeApp(options: DevFirebaseOptions.current);

  if (AppConfig.useFirebaseEmulator) {
    await FirebaseAuth.instance.useAuthEmulator(AppConfig.emulatorHost, AppConfig.authEmulatorPort);
    debugPrint('[firebase] Auth emulator → ${AppConfig.emulatorHost}:${AppConfig.authEmulatorPort}');
  }
  debugPrint('[api] base url → ${AppConfig.apiBaseUrl}');
}
