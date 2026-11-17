import 'package:flutter/material.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/widgets/category_colors.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_status.dart';
import 'status_style.dart';
import 'task_check_button.dart';

enum _TaskMenuAction { edit, delete }

/// Görev kartı. Sağa kaydır: tamamla / geri al. Sola kaydır: sil.
class TaskCard extends StatefulWidget {
  const TaskCard({
    required this.task,
    required this.onToggleDone,
    required this.onStatusChanged,
    required this.onEdit,
    required this.onDelete,
    this.category,
    this.now,
    super.key,
  });

  final Task task;
  final Category? category;
  final VoidCallback onToggleDone;
  final ValueChanged<TaskStatus> onStatusChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Test için sabit "şimdi".
  final DateTime? now;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final task = widget.task;
    final now = widget.now ?? DateTime.now();
    final isDone = task.isDone;
    final showMenu = _hovered || context.windowSize == WindowSize.compact;
    final preview = task.descriptionPreview;

    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TaskCheckButton(status: task.status, onPressed: widget.onToggleDone),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDone ? scheme.onSurfaceVariant : scheme.onSurface,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (preview != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusBadge(status: task.status, onChanged: widget.onStatusChanged),
                          if (task.dueDate != null) _DueDate(task: task, now: now),
                          if (widget.category != null) _CategoryLabel(category: widget.category!),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: showMenu ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: PopupMenuButton<_TaskMenuAction>(
                  tooltip: 'Görev işlemleri',
                  icon: Icon(Icons.more_vert, size: 20, color: scheme.onSurfaceVariant),
                  onSelected: (a) => a == _TaskMenuAction.edit ? widget.onEdit() : widget.onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _TaskMenuAction.edit,
                      child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Düzenle')),
                    ),
                    PopupMenuItem(
                      value: _TaskMenuAction.delete,
                      child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Sil')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final colors = context.statusColors;
    return Dismissible(
      key: ValueKey('task-${task.id}'),
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: isDone ? colors.todo : colors.done,
        icon: isDone ? Icons.undo_rounded : Icons.check_rounded,
        label: isDone ? 'Geri al' : 'Tamamla',
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: scheme.error,
        icon: Icons.delete_outline,
        label: 'Sil',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.onToggleDone();
          return false; // kart yerinde kalır, yalnızca durum değişir
        }
        return true;
      },
      onDismissed: (_) => widget.onDelete(),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: card,
      ),
    );
  }
}

class _DueDate extends StatelessWidget {
  const _DueDate({required this.task, required this.now});

  final Task task;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = task.isOverdue(now);
    final color = overdue ? context.statusColors.overdue : theme.colorScheme.onSurfaceVariant;
    final label = relativeDayLabel(task.dueDate!, now: now);
    return Tooltip(
      message: longDateLabel(task.dueDate!),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(overdue ? Icons.event_busy_outlined : Icons.event_outlined, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            overdue ? 'Gecikti · $label' : label,
            style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: overdue ? FontWeight.w600 : null),
          ),
        ],
      ),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CategoryDot(hex: category.color, size: 8),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(
            category.name,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({required this.alignment, required this.color, required this.icon, required this.label});

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black;
    final isLeft = alignment == Alignment.centerLeft;
    final content = [
      Icon(icon, color: onColor),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: onColor, fontWeight: FontWeight.w600)),
    ];
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      child: Row(mainAxisSize: MainAxisSize.min, children: isLeft ? content : content.reversed.toList()),
    );
  }
}
