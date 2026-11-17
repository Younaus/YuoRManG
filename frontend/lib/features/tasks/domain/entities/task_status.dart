enum TaskStatus {
  todo('todo', 'Yapılacak'),
  inProgress('in_progress', 'Devam ediyor'),
  done('done', 'Tamamlandı');

  const TaskStatus(this.apiValue, this.label);

  /// Backend'deki değer.
  final String apiValue;

  /// Arayüzde gösterilen ad.
  final String label;

  static TaskStatus fromApi(String value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => TaskStatus.todo);
}

enum TaskSort {
  createdAt('createdAt', 'En yeni'),
  dueDate('dueDate', 'Bitiş tarihi');

  const TaskSort(this.apiValue, this.label);

  final String apiValue;
  final String label;
}
