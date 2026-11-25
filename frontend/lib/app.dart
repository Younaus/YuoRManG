import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'features/tasks/presentation/widgets/corner_focus_pill.dart';
import 'features/tasks/presentation/widgets/desktop_shell_host.dart';
import 'features/tasks/presentation/widgets/offline_banner.dart';
import 'features/tasks/presentation/widgets/reminder_host.dart';
import 'features/tasks/presentation/widgets/sync_widgets.dart';

class YouRManGApp extends ConsumerWidget {
  const YouRManGApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'YouRManG',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Windows Mini Köşe Modu: açıkken pencereyi köşe hapı doldurur (diğer platformlarda etkisiz).
      // Windows tepsi eylemleri; öne gelince kategorileri + görevleri yenile (5 sn bekleme ile).
      builder: (context, child) => DesktopShellHost(
        child: ReminderHost(
          child: SyncOnResume(
            // Çevrimdışı şeridi tam pencere arayüzünün parçası: köşe kapsülünde görünmez.
            child: CornerModeHost(child: OfflineBanner(child: child ?? const SizedBox.shrink())),
          ),
        ),
      ),
    );
  }
}
