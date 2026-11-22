import 'package:flutter/foundation.dart';

/// Derleme zamanı yapılandırması (`--dart-define` ile geçersiz kılınabilir).
///
/// Varsayılan: canlı Firebase projesi (`yourmang`) ve canlı API.
///
/// Örnekler:
///   flutter run -d windows                                   # prod
///   flutter run -d windows --dart-define=USE_EMULATORS=true  # yerel emülatörler (cd backend && npm run serve)
///   flutter run --dart-define=API_BASE_URL=https://api.example.com/v1
abstract final class AppConfig {
  /// `true` ise Auth (9199) ve Functions (5101) yerel emülatörleri kullanılır. Varsayılan: prod.
  static const bool useEmulators = bool.fromEnvironment('USE_EMULATORS', defaultValue: false);

  /// Canlı Firebase projesi.
  static const String firebaseProjectId = 'yourmang';

  /// Emülatörlerin çalıştığı proje (`demo-` öneki: gerçek kaynaklara asla bağlanmaz).
  static const String emulatorProjectId = String.fromEnvironment(
    'EMULATOR_PROJECT_ID',
    defaultValue: 'demo-yourmang',
  );

  static const String functionsRegion = 'europe-west1';

  /// Canlı API (Cloud Functions Gen 2, europe-west1) — `/v1` dahil.
  static const String productionApiBaseUrl = 'https://europe-west1-yourmang.cloudfunctions.net/api/v1';

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

  /// Yerel Functions emülatöründeki API adresi (`/v1` dahil).
  static String get emulatorApiBaseUrl =>
      'http://$emulatorHost:$functionsEmulatorPort/$emulatorProjectId/$functionsRegion/api/v1';

  /// Backend API taban adresi (`/v1` dahil): `API_BASE_URL` → emülatör → canlı.
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    return useEmulators ? emulatorApiBaseUrl : productionApiBaseUrl;
  }
}
