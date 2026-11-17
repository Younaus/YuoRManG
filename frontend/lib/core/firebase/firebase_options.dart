import 'package:firebase_core/firebase_core.dart';

import '../config/app_config.dart';

/// Geliştirme (emülatör) için Firebase ayarları.
///
/// `demo-` önekli proje ID'si gerçek bir Firebase projesi gerektirmez. Gerçek projeye geçerken
/// `flutterfire configure` ile üretilen `firebase_options.dart` bu dosyanın yerini almalıdır.
abstract final class DevFirebaseOptions {
  static const FirebaseOptions current = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: AppConfig.firebaseProjectId,
    authDomain: '${AppConfig.firebaseProjectId}.firebaseapp.com',
  );
}
