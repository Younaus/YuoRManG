import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/categories/presentation/widgets/category_tree_panel.dart';

/// Masaüstü sabit yan menüsü: marka, görünümler + kategori ağacı, ayarlar ve kullanıcı.
class AppSidebar extends ConsumerWidget {
  const AppSidebar({required this.navigationShell, super.key});

  static const width = 288.0;

  final StatefulNavigationShell navigationShell;

  static const _tasksBranch = 0;
  static const _settingsBranch = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = ref.watch(authStateProvider).value;
    final onTasks = navigationShell.currentIndex == _tasksBranch;
    final onSettings = navigationShell.currentIndex == _settingsBranch;

    return Material(
      color: scheme.surfaceContainerLow,
      child: SizedBox(
        width: width,
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(9)),
                      child: Icon(Icons.task_alt_rounded, size: 20, color: scheme.onPrimary),
                    ),
                    const SizedBox(width: 12),
                    Text('YouRManG', style: theme.textTheme.titleMedium?.copyWith(letterSpacing: -0.2)),
                  ],
                ),
              ),
              Expanded(
                child: CategoryTreePanel(
                  highlightSelection: onTasks,
                  onScopeSelected: (_) => navigationShell.goBranch(_tasksBranch),
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Material(
                  color: onSettings ? scheme.secondaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    key: const Key('sidebar.settings'),
                    dense: true,
                    leading: Icon(onSettings ? Icons.settings : Icons.settings_outlined, size: 20),
                    title: const Text('Ayarlar'),
                    onTap: () => navigationShell.goBranch(_settingsBranch),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        user?.initials ?? '?',
                        style: theme.textTheme.labelMedium?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.label ?? '', overflow: TextOverflow.ellipsis, style: theme.textTheme.labelLarge),
                          if (user?.email != null)
                            Text(
                              user!.email!,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
