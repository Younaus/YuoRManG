import 'package:flutter/material.dart';

/// Görev durumları için tema uyumlu renkler (yapılacak: gri, devam ediyor: amber, tamamlandı: yeşil).
/// Kullanım: `Theme.of(context).extension<StatusColors>()!`
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
    required this.overdueContainer,
  });

  static const light = StatusColors(
    todo: Color(0xFF64748B),
    todoContainer: Color(0xFFF1F5F9),
    inProgress: Color(0xFFD97706),
    inProgressContainer: Color(0xFFFEF3C7),
    done: Color(0xFF059669),
    doneContainer: Color(0xFFD1FAE5),
    overdue: Color(0xFFDC2626),
    overdueContainer: Color(0xFFFEE2E2),
  );

  static const dark = StatusColors(
    todo: Color(0xFF94A3B8),
    todoContainer: Color(0xFF1E293B),
    inProgress: Color(0xFFFBBF24),
    inProgressContainer: Color(0xFF3A2A06),
    done: Color(0xFF34D399),
    doneContainer: Color(0xFF07322A),
    overdue: Color(0xFFF87171),
    overdueContainer: Color(0xFF3B1218),
  );

  final Color todo;
  final Color todoContainer;
  final Color inProgress;
  final Color inProgressContainer;
  final Color done;
  final Color doneContainer;
  final Color overdue;
  final Color overdueContainer;

  @override
  StatusColors copyWith({
    Color? todo,
    Color? todoContainer,
    Color? inProgress,
    Color? inProgressContainer,
    Color? done,
    Color? doneContainer,
    Color? overdue,
    Color? overdueContainer,
  }) {
    return StatusColors(
      todo: todo ?? this.todo,
      todoContainer: todoContainer ?? this.todoContainer,
      inProgress: inProgress ?? this.inProgress,
      inProgressContainer: inProgressContainer ?? this.inProgressContainer,
      done: done ?? this.done,
      doneContainer: doneContainer ?? this.doneContainer,
      overdue: overdue ?? this.overdue,
      overdueContainer: overdueContainer ?? this.overdueContainer,
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
      overdueContainer: Color.lerp(overdueContainer, other.overdueContainer, t)!,
    );
  }
}
