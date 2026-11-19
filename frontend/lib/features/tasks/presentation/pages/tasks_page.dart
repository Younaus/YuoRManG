import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/widgets/brand.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/domain/entities/category_tree.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_tree_panel.dart';
import '../../domain/entities/task_query.dart';
import '../providers/task_providers.dart';
import '../widgets/corner_focus_pill.dart';
import '../widgets/task_filter_bar.dart';
import '../widgets/task_form.dart';
import '../widgets/task_list_view.dart';
import '../widgets/task_overview_card.dart';
import '../widgets/task_search_field.dart';

/// Ana görev ekranı.
///  - Masaüstü: ferah başlık (yol + başlık), arama, köşe modu (Windows) ve tema düğmesi;
///    "Yeni görev" yan menüde.
///  - Mobil/tablet: logolu üst çubuk, kategori çekmecesi, arama, filtre çipleri ve yuvarlak FAB.
class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void _newTask() => showNewTaskForm(context, ref);

  @override
  Widget build(BuildContext context) {
    final size = context.windowSize;
    final isExpanded = size == WindowSize.expanded;
    final isCompact = size == WindowSize.compact;
    final scope = ref.watch(selectedScopeProvider);
    final tree = ref.watch(categoryTreeProvider).value ?? CategoryTree.empty;
    final title = scopeTitle(scope, tree);
    final breadcrumb = scopeBreadcrumb(scope, tree);
    final hPad = isCompact ? 16.0 : 28.0;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _newTask,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _searchFocus.requestFocus,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: isExpanded
              ? null
              : AppBar(
                  toolbarHeight: 64,
                  titleSpacing: 0,
                  leading: Builder(
                    builder: (ctx) => IconButton(
                      tooltip: 'Kategoriler',
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  title: AppTitleBlock(title: title, overline: breadcrumb ?? 'YouRManG', showLogo: isCompact),
                  actions: const [CornerModeButton(), _AccountButton(), SizedBox(width: 12)],
                ),
          drawer: isExpanded
              ? null
              : Drawer(
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: AppTitleBlock(title: 'Kategoriler'),
                        ),
                        Expanded(child: CategoryTreePanel(onScopeSelected: (_) => Navigator.of(context).maybePop())),
                      ],
                    ),
                  ),
                ),
          floatingActionButton: isCompact
              ? AppFab(key: const Key('tasks.fab'), tooltip: 'Yeni görev', onPressed: _newTask)
              : null,
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isExpanded)
                      _DesktopHeader(title: title, breadcrumb: breadcrumb, searchFocus: _searchFocus)
                    else
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 4),
                        child: Row(
                          children: [
                            Expanded(child: TaskSearchField(focusNode: _searchFocus)),
                            if (!isCompact) ...[const SizedBox(width: 12), _NewTaskButton(onPressed: _newTask)],
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    TaskFilterBar(padding: EdgeInsets.symmetric(horizontal: hPad)),
                    const SizedBox(height: 6),
                    Expanded(
                      child: TaskListView(
                        onCreateTask: _newTask,
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        header: const TaskOverviewCard(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Üst çubuktaki avatar: Ayarlar sekmesine götürür.
class _AccountButton extends ConsumerWidget {
  const _AccountButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    return Tooltip(
      message: 'Hesap ve ayarlar',
      child: InkResponse(
        onTap: () => context.go(AppRoutes.settings),
        radius: 24,
        child: UserAvatar(user: user, radius: 18),
      ),
    );
  }
}

/// Açık ↔ koyu tema düğmesi (masaüstü başlığı).
class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      key: const Key('tasks.themeToggle'),
      tooltip: isDark ? 'Açık temaya geç' : 'Koyu temaya geç',
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => ref.read(themeModeProvider.notifier).setMode(isDark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.title, required this.breadcrumb, required this.searchFocus});

  final String title;
  final String? breadcrumb;
  final FocusNode searchFocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder_open_rounded, size: 15, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        breadcrumb ?? 'Çalışma alanı',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(title, overflow: TextOverflow.ellipsis, style: theme.textTheme.headlineSmall),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 340,
            child: TaskSearchField(focusNode: searchFocus, shortcutHint: 'Ctrl F'),
          ),
          const SizedBox(width: 8),
          const CornerModeButton(),
          const _ThemeToggle(),
        ],
      ),
    );
  }
}

class _NewTaskButton extends StatelessWidget {
  const _NewTaskButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Yeni görev (Ctrl+N)',
      child: FilledButton.icon(
        key: const Key('tasks.newTask'),
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Yeni görev'),
      ),
    );
  }
}

String scopeTitle(TaskScope scope, CategoryTree tree) => switch (scope) {
  AllTasksScope() => 'Tüm görevler',
  UncategorizedScope() => 'Kategorisiz',
  CategoryScope(:final categoryId) => tree[categoryId]?.name ?? 'Kategori',
};

/// Üst kategoriler: "İş › Projeler"
String? scopeBreadcrumb(TaskScope scope, CategoryTree tree) {
  if (scope is! CategoryScope) return null;
  final path = tree.pathTo(scope.categoryId);
  if (path.length < 2) return null;
  return path.take(path.length - 1).map((c) => c.name).join(' › ');
}
