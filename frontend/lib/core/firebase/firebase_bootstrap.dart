import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'firebase_options.dart';

/// Canlı projenin ayarları. Web için ayrı uygulama kaydı yok: Windows kaydı zaten bir
/// Firebase *web* uygulaması olduğundan tarayıcıda da onu kullanırız.
FirebaseOptions get _platformOptions => kIsWeb ? DefaultFirebaseOptions.windows : DefaultFirebaseOptions.currentPlatform;

/// Emülatörde, token'ların Functions emülatörü tarafından doğrulanabilmesi için proje ID'si
/// emülatör projesiyle aynı olmalı.
FirebaseOptions get firebaseOptions => AppConfig.useEmulators
    ? _platformOptions.copyWith(
        projectId: AppConfig.emulatorProjectId,
        authDomain: '${AppConfig.emulatorProjectId}.firebaseapp.com',
      )
    : _platformOptions;

/// Firebase'i başlatır; `USE_EMULATORS=true` ise Auth emülatörüne bağlanır.
Future<void> initFirebase() async {
  await Firebase.initializeApp(options: firebaseOptions);

  if (AppConfig.useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(AppConfig.emulatorHost, AppConfig.authEmulatorPort);
    debugPrint('[firebase] Auth emulator → ${AppConfig.emulatorHost}:${AppConfig.authEmulatorPort}');
  }
  debugPrint('[api] base url → ${AppConfig.apiBaseUrl}');
}
