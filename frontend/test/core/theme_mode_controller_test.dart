import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourmang/core/storage/shared_preferences_provider.dart';
import 'package:yourmang/core/theme/app_theme.dart';
import 'package:yourmang/core/theme/status_colors.dart';
import 'package:yourmang/core/theme/theme_mode_controller.dart';

void main() {
  Future<ProviderContainer> container(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    return c;
  }

  test('varsayılan tema modu system', () async {
    final c = await container({});
    expect(c.read(themeModeProvider), ThemeMode.system);
  });

  test('kayıtlı tercih okunur, değişiklik kalıcı olur', () async {
    final c = await container({ThemeModeController.storageKey: 'light'});
    expect(c.read(themeModeProvider), ThemeMode.light);

    await c.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    expect(c.read(themeModeProvider), ThemeMode.dark);
    expect(c.read(sharedPreferencesProvider).getString(ThemeModeController.storageKey), 'dark');
  });

  test('bozuk kayıt system\'e düşer', () async {
    final c = await container({ThemeModeController.storageKey: 'purple'});
    expect(c.read(themeModeProvider), ThemeMode.system);
  });

  test('açık ve koyu tema StatusColors uzantısını içerir', () {
    expect(AppTheme.light().brightness, Brightness.light);
    expect(AppTheme.dark().brightness, Brightness.dark);
    expect(AppTheme.light().extension<StatusColors>(), StatusColors.light);
    expect(AppTheme.dark().extension<StatusColors>(), StatusColors.dark);
  });
}
