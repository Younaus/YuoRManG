import 'package:flutter/foundation.dart';

/// Derleme zamanı yapılandırması (`--dart-define` ile geçersiz kılınabilir).
///
/// Örnekler:
///   flutter run -d windows
///   flutter run -d chrome --dart-define=USE_FIREBASE_EMULATOR=false --dart-define=FIREBASE_PROJECT_ID=my-proj
///   flutter run --dart-define=API_BASE_URL=https://api.example.com/v1
abstract final class AppConfig {
  /// Debug derlemelerinde varsayılan olarak yerel Firebase emülatörleri kullanılır.
  static const bool useFirebaseEmulator = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: kDebugMode,
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'demo-yourmang',
  );

  static const String functionsRegion = 'europe-west1';

  // firebase.json'daki emülatör portları ile aynı olmalı.
  static const int authEmulatorPort = 9199;
  static const int functionsEmulatorPort = 5101;

  static const String _emulatorHostOverride = String.fromEnvironment('EMULATOR_HOST');
  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Android emülatörü host makineye 10.0.2.2 üzerinden erişir.
  static String get emulatorHost {
    if (_emulatorHostOverride.isNotEmpty) return _emulatorHostOverride;
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return isAndroid ? '10.0.2.2' : '127.0.0.1';
  }

  /// Backend API taban adresi (`/v1` dahil).
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    if (useFirebaseEmulator) {
      return 'http://$emulatorHost:$functionsEmulatorPort/$firebaseProjectId/$functionsRegion/api/v1';
    }
    return 'https://$functionsRegion-$firebaseProjectId.cloudfunctions.net/api/v1';
  }
}
