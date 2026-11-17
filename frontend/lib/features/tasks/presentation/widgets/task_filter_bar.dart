import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../domain/entities/task_status.dart';
import '../providers/task_providers.dart';
import 'status_style.dart';

/// Durum filtresi (çipler) + sıralama menüsü.
class TaskFilterBar extends ConsumerWidget {
  const TaskFilterBar({this.padding = const EdgeInsets.symmetric(horizontal: 16), super.key});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);
    final controller = ref.read(taskFilterProvider.notifier);
    final iconOnlySort = context.windowSize == WindowSize.compact;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Tümü',
                    selected: filter.status == null,
                    onSelected: () => controller.setStatus(null),
                  ),
                  for (final s in TaskStatus.values)
                    _FilterChip(
                      label: s.label,
                      dotColor: context.statusColors.of(s).fg,
                      selected: filter.status == s,
                      onSelected: () => controller.setStatus(filter.status == s ? null : s),
                    ),
                ],
              ),
            ),
          ),
          PopupMenuButton<TaskSort>(
            tooltip: 'Sırala: ${filter.sort.label}',
            initialValue: filter.sort,
            onSelected: controller.setSort,
            itemBuilder: (_) => [
              for (final s in TaskSort.values) CheckedPopupMenuItem(value: s, checked: s == filter.sort, child: Text(s.label)),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  if (!iconOnlySort) ...[
                    const SizedBox(width: 6),
                    Text(filter.sort.label, style: Theme.of(context).textTheme.labelLarge),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onSelected, this.dotColor});

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        avatar: dotColor == null
            ? null
            : Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
