import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/desktop/corner_window_service.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/notifications/reminder_service.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/widgets/brand.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../tasks/presentation/providers/corner_mode_providers.dart';
import '../../../tasks/presentation/providers/offline_sync_providers.dart';
import '../../../tasks/presentation/providers/reminder_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: AppTitleBlock(title: 'Ayarlar', showLogo: context.windowSize == WindowSize.compact),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Section(
                    title: 'Hesap',
                    child: ListTile(
                      leading: UserAvatar(user: user, radius: 20),
                      title: Text(user?.label ?? '-'),
                      subtitle: Text(user?.email ?? ''),
                      trailing: OutlinedButton.icon(
                        onPressed: () => _signOut(context, ref),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Çıkış yap'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Görünüm',
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tema', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 12),
                          SegmentedButton<ThemeMode>(
                            key: const Key('settings.themeMode'),
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                icon: Icon(Icons.brightness_auto_outlined),
                                label: Text('Sistem'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_outlined),
                                label: Text('Açık'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_outlined),
                                label: Text('Koyu'),
                              ),
                            ],
                            selected: {themeMode},
                            showSelectedIcon: false,
                            onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).setMode(s.first),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (ref.watch(reminderServiceProvider).isSupported) ...[
                    const SizedBox(height: 16),
                    const _Section(title: 'Hatırlatmalar', child: _RemindersTile()),
                  ],
                  if (ref.watch(cornerWindowServiceProvider).isSupported) ...[
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Masaüstü',
                      child: SwitchListTile(
                        key: const Key('settings.cornerOnMinimize'),
                        secondary: const Icon(Icons.picture_in_picture_alt_outlined),
                        title: const Text('Küçültünce köşe moduna geç'),
                        subtitle: const Text('Aktif görev varken pencereyi küçültünce otomatik olarak köşe moduna geç'),
                        value: ref.watch(cornerModeOnMinimizeProvider),
                        onChanged: ref.read(cornerModeOnMinimizeProvider.notifier).set,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Geliştirici',
                    child: ListTile(
                      leading: const Icon(Icons.dns_outlined),
                      title: const Text('API adresi'),
                      subtitle: SelectableText(AppConfig.apiBaseUrl),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Çıkışta bu cihazdaki önbellek ve gönderilmemiş değişiklikler silinir; bekleyen varsa önce sorulur.
Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  final pending = ref.read(offlineSyncProvider).pending;
  if (pending > 0) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gönderilmemiş değişiklikler var'),
        content: Text('$pending değişiklik henüz sunucuya gönderilmedi. Çıkış yaparsanız bu cihazdan silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Vazgeç')),
          FilledButton(
            key: const Key('settings.signOutConfirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yine de çıkış yap'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
  }
  await ref.read(authRepositoryProvider).signOut();
}

/// "Hatırlatmaları Aç/Kapat": açarken (Android 13+) bildirim izni istenir.
class _RemindersTile extends ConsumerWidget {
  const _RemindersTile();

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(reminderProvider.notifier).setEnabled(value);
    ref.invalidate(reminderPermissionProvider);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Bildirim izni verilmedi. Hatırlatmalar için sistem ayarlarından izin verin.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderProvider);
    final permitted = ref.watch(reminderPermissionProvider).value ?? true;
    final needsPermission = state.enabled && !permitted;
    return SwitchListTile(
      key: const Key('settings.reminders'),
      secondary: Icon(needsPermission ? Icons.notifications_off_outlined : Icons.notifications_active_outlined),
      title: const Text('Hatırlatmaları Aç/Kapat'),
      subtitle: Text(
        needsPermission
            ? 'Bildirim izni kapalı — hatırlatma gösterilemiyor. Açmak için anahtara dokunun.'
            : 'Bitiş zamanı gelen görevler için cihaz bildirimi (saat yoksa o gün 09:00)'
                  '${state.enabled && state.scheduled > 0 ? ' · ${state.scheduled} hatırlatma kurulu' : ''}',
      ),
      value: state.enabled && permitted,
      onChanged: (v) => _toggle(context, ref, v),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(text: title, padding: const EdgeInsets.only(left: 4, bottom: 8)),
        Card(child: child),
      ],
    );
  }
}
