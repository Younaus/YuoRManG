import '../../domain/entities/task.dart';
import '../../domain/entities/task_status.dart';
import '../models/task_dto.dart';

/// Çevrimdışıyken oluşturulan görevlerin geçici kimlik öneki.
const localTaskIdPrefix = 'local-';

bool isLocalTaskId(String id) => id.startsWith(localTaskIdPrefix);

enum PendingTaskOpKind { create, setStatus, delete }

/// Çevrimdışı işlem kuyruğundaki tek bir işlem (sırayla canlı API'ye gönderilir).
class PendingTaskOp {
  const PendingTaskOp._({required this.kind, required this.taskId, this.task, this.status});

  /// Yerel (geçici kimlikli) görevi oluştur. [task] tam halidir: kuyruktaki sonraki
  /// değişiklikler (durum, düzenleme) bu kayda katlanır.
  PendingTaskOp.create(Task task) : this._(kind: PendingTaskOpKind.create, taskId: task.id, task: task);

  const PendingTaskOp.setStatus(String taskId, TaskStatus status)
    : this._(kind: PendingTaskOpKind.setStatus, taskId: taskId, status: status);

  const PendingTaskOp.delete(String taskId) : this._(kind: PendingTaskOpKind.delete, taskId: taskId);

  factory PendingTaskOp.fromJson(Map<String, dynamic> json) {
    final kind = PendingTaskOpKind.values.byName(json['kind'] as String);
    final taskId = json['taskId'] as String;
    return switch (kind) {
      PendingTaskOpKind.create => PendingTaskOp.create(taskFromJson(json['task'] as Map<String, dynamic>)),
      PendingTaskOpKind.setStatus => PendingTaskOp.setStatus(taskId, TaskStatus.fromApi(json['status'] as String)),
      PendingTaskOpKind.delete => PendingTaskOp.delete(taskId),
    };
  }

  final PendingTaskOpKind kind;
  final String taskId;
  final Task? task;
  final TaskStatus? status;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'taskId': taskId,
    if (task != null) 'task': taskToJson(task!),
    if (status != null) 'status': status!.apiValue,
  };

  @override
  String toString() => 'PendingTaskOp(${kind.name} $taskId${status != null ? ' → ${status!.apiValue}' : ''})';
}

/// İşlemi kuyruğa ekler ve gereksiz istekleri birleştirir:
///  - yerel görevde durum değişikliği / düzenleme → bekleyen "create" kaydına katlanır
///  - yerel görevi silmek → "create" ve ona ait her şey kuyruktan çıkar (hiç gönderilmez)
///  - aynı görevde art arda durum değişikliği → yalnızca sonuncusu kalır
///  - sunucudaki görevi silmek → o görevin bekleyen durum değişiklikleri düşer
List<PendingTaskOp> enqueuePendingOp(List<PendingTaskOp> queue, PendingTaskOp op) {
  final pendingCreate = queue.where((q) => q.kind == PendingTaskOpKind.create && q.taskId == op.taskId).firstOrNull;
  switch (op.kind) {
    case PendingTaskOpKind.create:
      if (pendingCreate != null) {
        // Yerel görevin düzenlenmiş hâli: kaydı yerinde güncelle.
        return [for (final q in queue) q == pendingCreate ? op : q];
      }
      return [...queue, op];
    case PendingTaskOpKind.setStatus:
      if (pendingCreate != null) {
        final task = pendingCreate.task!;
        final updated = task.copyWith(
          status: op.status!,
          completedAt: op.status == TaskStatus.done ? DateTime.now() : null,
        );
        return [for (final q in queue) q == pendingCreate ? PendingTaskOp.create(updated) : q];
      }
      return [
        for (final q in queue)
          if (!(q.kind == PendingTaskOpKind.setStatus && q.taskId == op.taskId)) q,
        op,
      ];
    case PendingTaskOpKind.delete:
      if (pendingCreate != null) {
        return [
          for (final q in queue)
            if (q.taskId != op.taskId) q,
        ];
      }
      return [
        for (final q in queue)
          if (q.taskId != op.taskId) q,
        op,
      ];
  }
}

/// Bekleyen işlemleri bir görev listesine uygular (sunucu yanıtı henüz bunları içermezken).
List<Task> applyPendingOps(List<Task> tasks, List<PendingTaskOp> queue) {
  if (queue.isEmpty) return tasks;
  final byId = {for (final t in tasks) t.id: t};
  for (final op in queue) {
    switch (op.kind) {
      case PendingTaskOpKind.create:
        byId[op.taskId] = op.task!;
      case PendingTaskOpKind.setStatus:
        final t = byId[op.taskId];
        if (t != null) {
          byId[op.taskId] = t.copyWith(
            status: op.status!,
            completedAt: op.status == TaskStatus.done ? (t.completedAt ?? DateTime.now()) : null,
          );
        }
      case PendingTaskOpKind.delete:
        byId.remove(op.taskId);
    }
  }
  return byId.values.toList();
}
