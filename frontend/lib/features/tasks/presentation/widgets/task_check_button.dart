import 'package:flutter/material.dart';

import '../../domain/entities/task_status.dart';
import 'status_style.dart';

/// Kartın solundaki belirgin dairesel tamamlama butonu.
///  - yapılacak: ince gri halka
///  - devam ediyor: amber halka + iç nokta
///  - tamamlandı: dolu indigo daire + beyaz onay
class TaskCheckButton extends StatelessWidget {
  const TaskCheckButton({required this.status, required this.onPressed, super.key});

  final TaskStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.statusColors;
    final isDone = status == TaskStatus.done;
    final borderColor = switch (status) {
      TaskStatus.done => scheme.primary,
      TaskStatus.inProgress => colors.inProgress,
      TaskStatus.todo => scheme.outline.withValues(alpha: 0.7),
    };

    return Tooltip(
      message: isDone ? 'Tamamlanmadı olarak işaretle' : 'Tamamlandı olarak işaretle',
      child: Semantics(
        button: true,
        checked: isDone,
        child: InkResponse(
          onTap: onPressed,
          radius: 22,
          child: SizedBox.square(
            dimension: 40,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? scheme.primary : Colors.transparent,
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: isDone
                      ? [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isDone
                    ? Icon(Icons.check_rounded, size: 16, color: scheme.onPrimary)
                    : status == TaskStatus.inProgress
                    ? Center(
                        child: Container(
                          width: 9,
                          height: 9,
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
