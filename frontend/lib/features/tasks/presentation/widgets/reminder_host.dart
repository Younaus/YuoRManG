import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/reminder_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/reminder_providers.dart';

/// Uygulamanın kökünde: oturum açılınca hatırlatmaları eşitler, oturum kapanınca temizler ve
/// (Android 13+) bildirim iznini bir kez, önce ne işe yaradığını açıklayarak ister.
class ReminderHost extends ConsumerStatefulWidget {
  const ReminderHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ReminderHost> createState() => _ReminderHostState();
}

class _ReminderHostState extends ConsumerState<ReminderHost> {
  bool _prompting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onSession(ref.read(currentUidProvider)));
  }

  Future<void> _onSession(String? uid) async {
    if (!mounted || uid == null) return;
    final service = ref.read(reminderServiceProvider);
    if (!service.isSupported) return;
    final reminders = ref.read(reminderProvider.notifier);
    if (ref.read(reminderProvider).enabled && !await service.hasPermission()) await _askPermissionOnce();
    reminders.requestSync();
  }

  /// Açılış / giriş ekranındaki diyaloglar router ana kabuğa geçerken kapatılır: önce oraya varılmasını bekle.
  Future<void> _waitForAppShell() async {
    final delegate = ref.read(routerProvider).routerDelegate;
    bool ready() => !AppRoutes.public.contains(delegate.currentConfiguration.uri.path);
    if (!ready()) {
      final arrived = Completer<void>();
      void listener() {
        if (ready() && !arrived.isCompleted) arrived.complete();
      }

      delegate.addListener(listener);
      await arrived.future.timeout(const Duration(seconds: 15), onTimeout: () {});
      delegate.removeListener(listener);
    }
    await WidgetsBinding.instance.endOfFrame;
  }

  /// Sistem penceresinden önce kısa bir açıklama; "Şimdi değil" denirse bir daha sorulmaz (Ayarlar'dan açılabilir).
  Future<void> _askPermissionOnce() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (_prompting || (prefs.getBool(ReminderController.permissionAskedKey) ?? false)) return;
    _prompting = true;
    await _waitForAppShell();
    _prompting = false;
    if (!mounted) return;
    final context = ref.read(routerProvider).routerDelegate.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    _prompting = true;
    try {
      final allow = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const Key('reminders.permissionDialog'),
          icon: const Icon(Icons.notifications_active_outlined),
          title: const Text('Görev hatırlatmaları'),
          content: const Text(
            'Bitiş zamanı gelen görevler için bu cihazda bildirim gösterebiliriz '
            '(saat belirtilmemişse o gün 09:00\'da). Bunun için bildirim izni gerekiyor.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Şimdi değil')),
            FilledButton(
              key: const Key('reminders.allow'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('İzin ver'),
            ),
          ],
        ),
      );
      await prefs.setBool(ReminderController.permissionAskedKey, true);
      if (allow ?? false) {
        await ref.read(reminderServiceProvider).requestPermission();
        ref.invalidate(reminderPermissionProvider);
      }
    } finally {
      _prompting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(reminderSessionGuardProvider);
    ref.listen(reminderProvider, (_, _) {});
    ref.listen(currentUidProvider, (_, uid) => _onSession(uid));
    return widget.child;
  }
}
