import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../categories/domain/entities/category_tree.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_tree_panel.dart';
import '../../domain/entities/task_query.dart';
import '../providers/task_providers.dart';
import '../widgets/task_filter_bar.dart';
import '../widgets/task_form.dart';
import '../widgets/task_list_view.dart';
import '../widgets/task_search_field.dart';

/// Ana görev ekranı. Masaüstünde başlık + arama + "Yeni görev" üstte; mobilde AppBar,
/// kategori çekmecesi ve FAB.
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

  void _newTask() {
    final scope = ref.read(selectedScopeProvider);
    showTaskForm(context, defaultCategoryId: scope is CategoryScope ? scope.categoryId : null);
  }

  @override
  Widget build(BuildContext context) {
    final size = context.windowSize;
    final isExpanded = size == WindowSize.expanded;
    final isCompact = size == WindowSize.compact;
    final scope = ref.watch(selectedScopeProvider);
    final tree = ref.watch(categoryTreeProvider).value ?? CategoryTree.empty;
    final title = scopeTitle(scope, tree);
    final hPad = isCompact ? 16.0 : 24.0;

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
                  title: Text(title),
                  leading: Builder(
                    builder: (ctx) => IconButton(
                      tooltip: 'Kategoriler',
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                ),
          drawer: isExpanded
              ? null
              : Drawer(
                  child: SafeArea(
                    child: CategoryTreePanel(onScopeSelected: (_) => Navigator.of(context).maybePop()),
                  ),
                ),
          floatingActionButton: isCompact
              ? FloatingActionButton.extended(
                  key: const Key('tasks.fab'),
                  onPressed: _newTask,
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni görev'),
                )
              : null,
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isExpanded)
                      _DesktopHeader(
                        title: title,
                        breadcrumb: scopeBreadcrumb(scope, tree),
                        searchFocus: _searchFocus,
                        onNewTask: _newTask,
                      )
                    else
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 4),
                        child: Row(
                          children: [
                            Expanded(child: TaskSearchField(focusNode: _searchFocus)),
                            if (!isCompact) ...[
                              const SizedBox(width: 12),
                              _NewTaskButton(onPressed: _newTask),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    TaskFilterBar(padding: EdgeInsets.symmetric(horizontal: hPad)),
                    const SizedBox(height: 4),
                    Expanded(
                      child: TaskListView(
                        onCreateTask: _newTask,
                        padding: EdgeInsets.symmetric(horizontal: hPad),
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

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({
    required this.title,
    required this.breadcrumb,
    required this.searchFocus,
    required this.onNewTask,
  });

  final String title;
  final String? breadcrumb;
  final FocusNode searchFocus;
  final VoidCallback onNewTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (breadcrumb != null)
                  Text(
                    breadcrumb!,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                Text(title, overflow: TextOverflow.ellipsis, style: theme.textTheme.headlineSmall),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(width: 300, child: TaskSearchField(focusNode: searchFocus)),
          const SizedBox(width: 12),
          _NewTaskButton(onPressed: onNewTask),
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
        icon: const Icon(Icons.add, size: 20),
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
