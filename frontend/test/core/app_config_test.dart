import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/core/config/app_config.dart';
import 'package:yourmang/core/firebase/firebase_bootstrap.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('varsayılan ortam prod: emülatör kapalı, canlı API ve canlı proje', () {
    expect(AppConfig.useEmulators, isFalse);
    expect(AppConfig.apiBaseUrl, 'https://europe-west1-yourmang.cloudfunctions.net/api/v1');
    expect(AppConfig.apiBaseUrl, AppConfig.productionApiBaseUrl);

    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(firebaseOptions.projectId, 'yourmang');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(firebaseOptions.projectId, 'yourmang');
  });

  test('emülatör adresi firebase.json portları ve demo projesiyle kurulur', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(AppConfig.emulatorApiBaseUrl, 'http://127.0.0.1:5101/demo-yourmang/europe-west1/api/v1');
    expect(AppConfig.authEmulatorPort, 9199);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(AppConfig.emulatorApiBaseUrl, startsWith('http://10.0.2.2:5101/'));
  });
}
