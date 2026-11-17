import 'package:flutter/material.dart';

import '../../../../core/theme/status_colors.dart';
import '../../domain/entities/task_status.dart';

/// Duruma göre ön plan / zemin rengi (gri, amber, yeşil).
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

/// Kartlardaki küçük hap (pill) rozet: ikon/nokta + etiket.
class Pill extends StatelessWidget {
  const Pill({required this.label, required this.fg, required this.bg, this.icon, this.dot = false, super.key});

  final String label;
  final Color fg;
  final Color bg;
  final IconData? icon;

  /// İkon yerine renkli nokta göster.
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 14, color: fg)
          else if (dot)
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
          if (icon != null || dot) const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w600, height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Durum rozeti; dokununca durum seçme menüsü açılır.
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, this.onChanged, super.key});

  final TaskStatus status;
  final ValueChanged<TaskStatus>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.statusColors.of(status);
    final pill = Pill(
      label: status.label,
      fg: colors.fg,
      bg: colors.bg,
      icon: status == TaskStatus.done ? Icons.check_rounded : null,
      dot: status != TaskStatus.done,
    );
    if (onChanged == null) return pill;

    return PopupMenuButton<TaskStatus>(
      tooltip: 'Durumu değiştir',
      initialValue: status,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
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
