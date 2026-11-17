import 'package:flutter/material.dart';

/// Görev durumları için tema uyumlu renkler (yapılacak: gri, devam ediyor: sarı, tamamlandı: yeşil). Kullanım: `Theme.of(context).extension<StatusColors>()!`
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.todo,
    required this.todoContainer,
    required this.inProgress,
    required this.inProgressContainer,
    required this.done,
    required this.doneContainer,
    required this.overdue,
  });

  static const light = StatusColors(
    todo: Color(0xFF64748B),
    todoContainer: Color(0xFFF1F5F9),
    inProgress: Color(0xFFA16207),
    inProgressContainer: Color(0xFFFEF9C3),
    done: Color(0xFF16A34A),
    doneContainer: Color(0xFFDCFCE7),
    overdue: Color(0xFFDC2626),
  );

  static const dark = StatusColors(
    todo: Color(0xFF94A3B8),
    todoContainer: Color(0xFF1E293B),
    inProgress: Color(0xFFFACC15),
    inProgressContainer: Color(0xFF3A3104),
    done: Color(0xFF4ADE80),
    doneContainer: Color(0xFF052E16),
    overdue: Color(0xFFF87171),
  );

  final Color todo;
  final Color todoContainer;
  final Color inProgress;
  final Color inProgressContainer;
  final Color done;
  final Color doneContainer;
  final Color overdue;

  @override
  StatusColors copyWith({
    Color? todo,
    Color? todoContainer,
    Color? inProgress,
    Color? inProgressContainer,
    Color? done,
    Color? doneContainer,
    Color? overdue,
  }) {
    return StatusColors(
      todo: todo ?? this.todo,
      todoContainer: todoContainer ?? this.todoContainer,
      inProgress: inProgress ?? this.inProgress,
      inProgressContainer: inProgressContainer ?? this.inProgressContainer,
      done: done ?? this.done,
      doneContainer: doneContainer ?? this.doneContainer,
      overdue: overdue ?? this.overdue,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      todo: Color.lerp(todo, other.todo, t)!,
      todoContainer: Color.lerp(todoContainer, other.todoContainer, t)!,
      inProgress: Color.lerp(inProgress, other.inProgress, t)!,
      inProgressContainer: Color.lerp(inProgressContainer, other.inProgressContainer, t)!,
      done: Color.lerp(done, other.done, t)!,
      doneContainer: Color.lerp(doneContainer, other.doneContainer, t)!,
      overdue: Color.lerp(overdue, other.overdue, t)!,
    );
  }
}
