import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/network/retry_policy.dart';
import 'core/storage/shared_preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // Web: /#/tasks yerine /tasks

  final (prefs, _, _) = await (
    SharedPreferences.getInstance(),
    initFirebase(),
    initializeDateFormatting('tr_TR'),
  ).wait;

  runApp(
    ProviderScope(
      retry: appProviderRetry,
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const YouRManGApp(),
    ),
  );
}
