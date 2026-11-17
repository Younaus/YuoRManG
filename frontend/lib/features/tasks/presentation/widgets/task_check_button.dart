import 'package:flutter/material.dart';

import '../../domain/entities/task_status.dart';
import 'status_style.dart';

/// Kartın solundaki dairesel tamamlama butonu.
class TaskCheckButton extends StatelessWidget {
  const TaskCheckButton({required this.status, required this.onPressed, super.key});

  final TaskStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.statusColors;
    final isDone = status == TaskStatus.done;
    final borderColor = switch (status) {
      TaskStatus.done => colors.done,
      TaskStatus.inProgress => colors.inProgress,
      TaskStatus.todo => Theme.of(context).colorScheme.outline,
    };

    return Tooltip(
      message: isDone ? 'Tamamlanmadı olarak işaretle' : 'Tamamlandı olarak işaretle',
      child: Semantics(
        button: true,
        checked: isDone,
        child: InkResponse(
          onTap: onPressed,
          radius: 20,
          child: SizedBox.square(
            dimension: 36,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? colors.done : Colors.transparent,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: isDone
                    ? Icon(Icons.check_rounded, size: 15, color: Theme.of(context).colorScheme.surface)
                    : status == TaskStatus.inProgress
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: colors.inProgress, shape: BoxShape.circle),
                            ),
                          )
                        : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
