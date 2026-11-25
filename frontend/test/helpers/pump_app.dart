import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourmang/app.dart';
import 'package:yourmang/core/storage/shared_preferences_provider.dart';
import 'package:yourmang/features/auth/presentation/providers/auth_providers.dart';
import 'package:yourmang/features/categories/presentation/providers/category_providers.dart';
import 'package:yourmang/features/tasks/presentation/providers/task_providers.dart';

import 'fake_auth_repository.dart';
import 'fake_repositories.dart';

extension PumpApp on WidgetTester {
  /// Uygulamayı Firebase/ağ olmadan; sahte auth, sahte veri depoları ve bellek içi
  /// SharedPreferences ile başlatır. [size] mantıksal piksel cinsinden pencere boyutu.
  Future<SharedPreferences> pumpApp({
    required FakeAuthRepository auth,
    FakeTaskRepository? tasks,
    FakeCategoryRepository? categories,
    Map<String, Object> prefs = const {},
    Size size = const Size(800, 600),
    List<Override> overrides = const [],

    /// `true`: sahte depolar canlı API yerine geçer ve uygulamanın çevrimdışı önbellek/kuyruk katmanı çalışır.
    bool withOfflineLayer = false,
  }) async {
    await initializeDateFormatting('tr_TR');
    view.physicalSize = size * view.devicePixelRatio;
    addTearDown(view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    final categoryRepo = categories ?? FakeCategoryRepository();
    await pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          authRepositoryProvider.overrideWithValue(auth),
          if (withOfflineLayer) ...[
            categoryRemoteRepositoryProvider.overrideWithValue(categoryRepo),
            taskRemoteRepositoryProvider.overrideWithValue(tasks ?? FakeTaskRepository(categories: categoryRepo)),
          ] else ...[
            categoryRepositoryProvider.overrideWithValue(categoryRepo),
            taskRepositoryProvider.overrideWithValue(tasks ?? FakeTaskRepository(categories: categoryRepo)),
          ],
          ...overrides,
        ],
        child: const YouRManGApp(),
      ),
    );
    await pumpAndSettle();
    return sp;
  }
}
