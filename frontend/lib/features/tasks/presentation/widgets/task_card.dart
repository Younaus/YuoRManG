import 'package:flutter/material.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/widgets/category_colors.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_status.dart';
import 'status_style.dart';
import 'task_check_button.dart';

enum _TaskMenuAction { edit, delete }

/// Görev kartı: solda dairesel tamamlama butonu, sağda durum ve son tarih rozetleri.
/// Geniş kartlarda rozetler sağda tek sırada; dar kartlarda durum başlığın sağında,
/// tarih ve kategori altta. Sağa kaydır: tamamla / geri al. Sola kaydır: sil.
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

  /// Bu genişlikten itibaren rozetler sağ sütunda toplanır.
  static const wideBreakpoint = 560.0;

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
    final surfaces = context.surfaces;
    final task = widget.task;
    final now = widget.now ?? DateTime.now();
    final isDone = task.isDone;
    final showMenu = _hovered || context.windowSize == WindowSize.compact;
    final preview = task.descriptionPreview;
    const radius = BorderRadius.all(Radius.circular(AppTheme.radiusLg));

    final title = Text(
      task.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall?.copyWith(
        fontSize: 15,
        color: isDone ? scheme.onSurfaceVariant : scheme.onSurface,
        decoration: isDone ? TextDecoration.lineThrough : null,
        decorationColor: scheme.onSurfaceVariant,
      ),
    );
    final description = preview == null
        ? null
        : Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          );
    final status = StatusBadge(status: task.status, onChanged: widget.onStatusChanged);
    final due = task.dueDate == null ? null : _DueBadge(task: task, now: now);
    final category = widget.category == null ? null : _CategoryTag(category: widget.category!);
    final menu = AnimatedOpacity(
      opacity: showMenu ? 1 : 0,
      duration: const Duration(milliseconds: 120),
      child: PopupMenuButton<_TaskMenuAction>(
        tooltip: 'Görev işlemleri',
        position: PopupMenuPosition.under,
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
    );

    Widget narrowLayout() => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TaskCheckButton(status: task.status, onPressed: widget.onToggleDone),
        const SizedBox(width: 6),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 8),
                    Padding(padding: const EdgeInsets.only(top: 1), child: status),
                  ],
                ),
                if (description != null) ...[const SizedBox(height: 3), description],
                if (due != null || category != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [?due, ?category],
                  ),
                ],
              ],
            ),
          ),
        ),
        menu,
      ],
    );

    Widget wideLayout() => Row(
      children: [
        TaskCheckButton(status: task.status, onPressed: widget.onToggleDone),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              if (description != null || category != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (category != null) ...[category, if (description != null) const SizedBox(width: 12)],
                    if (description != null) Flexible(child: description),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (due != null) ...[due, const SizedBox(width: 8)],
        status,
        const SizedBox(width: 4),
        menu,
      ],
    );

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(borderRadius: radius, boxShadow: isDone ? null : surfaces.cardShadow),
      child: Material(
        color: isDone ? Color.alphaBlend(scheme.surface.withValues(alpha: 0.45), surfaces.card) : surfaces.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: _hovered ? scheme.primary.withValues(alpha: 0.35) : surfaces.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onEdit,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= TaskCard.wideBreakpoint;
              return Padding(
                padding: wide ? const EdgeInsets.fromLTRB(10, 12, 6, 12) : const EdgeInsets.fromLTRB(8, 8, 2, 14),
                child: wide ? wideLayout() : narrowLayout(),
              );
            },
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

/// Son tarih rozeti: gecikmişse kırmızı, bugünse indigo, diğerlerinde nötr.
class _DueBadge extends StatelessWidget {
  const _DueBadge({required this.task, required this.now});

  final Task task;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final due = task.dueDate!;
    final overdue = task.isOverdue(now);
    final isToday = !task.isDone && calendarDaysBetween(now, due) == 0;
    final label = relativeDayLabel(due, now: now);
    final (fg, bg, icon) = overdue
        ? (context.statusColors.overdue, context.statusColors.overdueContainer, Icons.event_busy_outlined)
        : isToday
        ? (scheme.primary, scheme.primary.withValues(alpha: 0.12), Icons.today_outlined)
        : (scheme.onSurfaceVariant, scheme.surfaceContainer, Icons.calendar_today_outlined);
    return Tooltip(
      message: longDateLabel(due),
      child: Pill(label: overdue ? 'Gecikti · $label' : label, fg: fg, bg: bg, icon: icon),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.category});

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
      Text(
        label,
        style: TextStyle(color: onColor, fontWeight: FontWeight.w600),
      ),
    ];
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      child: Row(mainAxisSize: MainAxisSize.min, children: isLeft ? content : content.reversed.toList()),
    );
  }
}
