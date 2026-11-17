import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourmang/app.dart';
import 'package:yourmang/core/storage/shared_preferences_provider.dart';
import 'package:yourmang/features/auth/presentation/providers/auth_providers.dart';

import 'fake_auth_repository.dart';

extension PumpApp on WidgetTester {
  /// Uygulamayı Firebase olmadan, sahte auth ve bellek içi SharedPreferences ile başlatır.
  Future<SharedPreferences> pumpApp({required FakeAuthRepository auth, Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    await pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: const YouRManGApp(),
      ),
    );
    await pumpAndSettle();
    return sp;
  }

  MediaQueryData get media => MediaQuery.of(element(find.byType(Navigator).first));
}
