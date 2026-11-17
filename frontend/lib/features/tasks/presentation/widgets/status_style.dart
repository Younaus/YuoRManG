import 'package:flutter/material.dart';

import '../../../../core/theme/status_colors.dart';
import '../../domain/entities/task_status.dart';

/// Duruma göre ön plan / zemin rengi (gri, sarı, yeşil).
extension StatusColorsX on StatusColors {
  ({Color fg, Color bg}) of(TaskStatus status) => switch (status) {
        TaskStatus.todo => (fg: todo, bg: todoContainer),
        TaskStatus.inProgress => (fg: inProgress, bg: inProgressContainer),
        TaskStatus.done => (fg: done, bg: doneContainer),
      };
}

extension StatusColorsContext on BuildContext {
  StatusColors get statusColors => Theme.of(this).extension<StatusColors>()!;
}

/// Durum etiketi; dokununca durum seçme menüsü açılır.
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, this.onChanged, super.key});

  final TaskStatus status;
  final ValueChanged<TaskStatus>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.statusColors.of(status);
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    if (onChanged == null) return pill;

    return PopupMenuButton<TaskStatus>(
      tooltip: 'Durumu değiştir',
      initialValue: status,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final s in TaskStatus.values)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: context.statusColors.of(s).fg, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Text(s.label),
              ],
            ),
          ),
      ],
      child: pill,
    );
  }
}
