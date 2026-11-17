import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_status.dart';
import '../providers/task_providers.dart';
import 'task_card.dart';
import 'task_form.dart';

/// Görev listesi: yükleniyor / hata / boş durumları, sonsuz kaydırma, kaydırarak işlemler.
class TaskListView extends ConsumerStatefulWidget {
  const TaskListView({required this.onCreateTask, this.padding = EdgeInsets.zero, super.key});

  final VoidCallback onCreateTask;
  final EdgeInsets padding;

  @override
  ConsumerState<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends ConsumerState<TaskListView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) ref.read(taskListProvider.notifier).loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  TaskListController get _controller => ref.read(taskListProvider.notifier);

  void _showError(Object error) {
    final message = error is ApiException ? error.message : 'İşlem başarısız oldu.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setStatus(Task task, TaskStatus status) async {
    try {
      await _controller.setStatus(task, status);
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  /// Önce listeden kaldırır, "Geri al" süresi dolunca sunucudan siler.
  Future<void> _deleteWithUndo(Task task) async {
    final controller = _controller;
    final messenger = ScaffoldMessenger.of(context);
    final index = controller.removeLocal(task.id);

    messenger.hideCurrentSnackBar();
    final reason = await messenger
        .showSnackBar(
          SnackBar(
            content: Text('"${task.title}" silindi'),
            duration: const Duration(seconds: 4),
            persist: false, // aksiyonlu SnackBar'lar varsayılan olarak kalıcı; otomatik kapansın
            action: SnackBarAction(label: 'Geri al', onPressed: () {}),
          ),
        )
        .closed;

    if (reason == SnackBarClosedReason.action) {
      controller.restoreLocal(task, index);
      return;
    }
    try {
      await controller.deleteRemote(task);
    } catch (e) {
      controller.restoreLocal(task, index);
      messenger.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Görev silinemedi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(visibleTasksProvider);
    final listState = ref.watch(taskListProvider);
    final filter = ref.watch(taskFilterProvider);
    final tree = ref.watch(categoryTreeProvider).value;

    final isReloading = listState.isLoading && listState.hasValue;

    return Column(
      children: [
        SizedBox(height: 2, child: isReloading ? const LinearProgressIndicator() : null),
        Expanded(
          child: tasks.when(
            skipLoadingOnReload: true,
            loading: () => _Skeleton(padding: widget.padding),
            error: (e, _) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Görevler yüklenemedi',
              message: e is ApiException ? e.message : null,
              action: FilledButton.tonal(
                onPressed: () => ref.invalidate(taskListProvider),
                child: const Text('Tekrar dene'),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return _EmptyTasks(filter: filter, onCreateTask: widget.onCreateTask);
              }
              final state = listState.value;
              return RefreshIndicator(
                onRefresh: _controller.refresh,
                child: ListView.separated(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: widget.padding.copyWith(top: widget.padding.top + 6, bottom: widget.padding.bottom + 96),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    if (i == items.length) return _Footer(state: state, onLoadMore: _controller.loadMore);
                    final task = items[i];
                    return TaskCard(
                      key: ValueKey(task.id),
                      task: task,
                      category: tree?[task.categoryId],
                      onToggleDone: () => _setStatus(task, task.isDone ? TaskStatus.todo : TaskStatus.done),
                      onStatusChanged: (s) => _setStatus(task, s),
                      onEdit: () => showTaskForm(context, task: task),
                      onDelete: () => _deleteWithUndo(task),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onLoadMore});

  final TaskListState? state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s == null || !s.hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: s.isLoadingMore
            ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
            : TextButton.icon(
                onPressed: onLoadMore,
                icon: Icon(s.loadMoreError != null ? Icons.refresh : Icons.expand_more),
                label: Text(s.loadMoreError != null ? 'Yüklenemedi — tekrar dene' : 'Daha fazla yükle'),
              ),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.filter, required this.onCreateTask});

  final TaskFilter filter;
  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    if (filter.search.trim().isNotEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Sonuç bulunamadı',
        message: '"${filter.search.trim()}" ile eşleşen görev yok.',
      );
    }
    if (filter.status != null) {
      return EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: '"${filter.status!.label}" durumunda görev yok',
      );
    }
    return EmptyState(
      icon: Icons.task_alt,
      title: 'Burada henüz görev yok',
      message: 'İlk görevinizi ekleyerek başlayın.',
      action: FilledButton.icon(onPressed: onCreateTask, icon: const Icon(Icons.add), label: const Text('Yeni görev')),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.padding});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        );
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding.copyWith(top: padding.top + 6),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 22, height: 22, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [bar(220.0 - i * 20, 14), const SizedBox(height: 8), bar(160, 10), const SizedBox(height: 12), bar(90, 16)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
