import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/task_status.dart';
import '../providers/task_providers.dart';
import 'status_style.dart';

/// Durum filtresi (hap çipler) + sıralama menüsü.
class TaskFilterBar extends ConsumerWidget {
  const TaskFilterBar({this.padding = const EdgeInsets.symmetric(horizontal: 16), super.key});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
          const SizedBox(width: 8),
          PopupMenuButton<TaskSort>(
            tooltip: 'Sırala: ${filter.sort.label}',
            initialValue: filter.sort,
            onSelected: controller.setSort,
            position: PopupMenuPosition.under,
            itemBuilder: (_) => [
              for (final s in TaskSort.values)
                CheckedPopupMenuItem(value: s, checked: s == filter.sort, child: Text(s.label)),
            ],
            child: Container(
              height: 36,
              padding: EdgeInsets.symmetric(horizontal: iconOnlySort ? 9 : 12),
              decoration: BoxDecoration(
                color: context.surfaces.card,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: context.surfaces.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  if (!iconOnlySort) ...[
                    const SizedBox(width: 6),
                    Text(
                      filter.sort.label,
                      style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface),
                    ),
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        labelStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: selected ? scheme.onPrimary : scheme.onSurface),
        side: BorderSide(color: selected ? scheme.primary : context.surfaces.border),
        avatar: dotColor == null
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: selected ? scheme.onPrimary : dotColor, shape: BoxShape.circle),
              ),
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
