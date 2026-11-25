import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/categories/presentation/widgets/category_tree_panel.dart';
import '../../features/tasks/presentation/widgets/task_form.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';

/// Masaüstü sabit yan menüsü: marka, "Yeni görev", görünümler + kategori ağacı ve kullanıcı kartı.
class AppSidebar extends ConsumerWidget {
  const AppSidebar({required this.navigationShell, super.key});

  static const width = 280.0;

  final StatefulNavigationShell navigationShell;

  // core/router/app_destinations.dart sırası.
  static const _tasksBranch = 0;
  static const _calendarBranch = 1;
  static const _settingsBranch = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = context.surfaces;
    final user = ref.watch(authStateProvider).value;
    final onTasks = navigationShell.currentIndex == _tasksBranch;
    final onSettings = navigationShell.currentIndex == _settingsBranch;
    final onCalendar = navigationShell.currentIndex == _calendarBranch;

    void newTask() {
      if (!onTasks) navigationShell.goBranch(_tasksBranch);
      showNewTaskForm(context, ref);
    }

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: surfaces.sidebar,
        border: Border(right: BorderSide(color: surfaces.border)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Row(
                children: [
                  const AppLogoMark(size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('YouRManG', style: theme.textTheme.titleMedium),
                        Text(
                          'Görev yöneticisi',
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Tooltip(
                message: 'Yeni görev (Ctrl+N)',
                child: FilledButton.icon(
                  key: const Key('tasks.newTask'),
                  onPressed: newTask,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Yeni görev'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _SidebarNavItem(
                key: const Key('sidebar.calendar'),
                icon: Icons.calendar_month_outlined,
                selectedIcon: Icons.calendar_month,
                label: 'Takvim',
                selected: onCalendar,
                onTap: () => navigationShell.goBranch(_calendarBranch),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: CategoryTreePanel(
                highlightSelection: onTasks,
                enableDragAndDrop: true,
                onScopeSelected: (_) => navigationShell.goBranch(_tasksBranch),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
              child: _UserCard(
                user: user,
                selected: onSettings,
                onOpenSettings: () => navigationShell.goBranch(_settingsBranch),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yan menüde tek satırlık gezinme öğesi (seçiliyken kategori satırları gibi dolu indigo).
class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    return Material(
      color: selected ? scheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(selected ? selectedIcon : icon, size: 20, color: selected ? fg : scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Text(label, style: theme.textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.selected, required this.onOpenSettings});

  final AppUser? user;
  final bool selected;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = context.surfaces;
    return Material(
      color: selected ? scheme.primary.withValues(alpha: 0.10) : surfaces.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: selected ? scheme.primary.withValues(alpha: 0.35) : surfaces.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onOpenSettings,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              UserAvatar(user: user, radius: 17),
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
              IconButton(
                key: const Key('sidebar.settings'),
                tooltip: 'Ayarlar',
                onPressed: onOpenSettings,
                color: selected ? scheme.primary : null,
                icon: Icon(selected ? Icons.settings : Icons.settings_outlined, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
