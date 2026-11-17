import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/widgets/brand.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

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
                        onPressed: () => ref.read(authRepositoryProvider).signOut(),
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
