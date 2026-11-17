import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';

/// Görev listesi — Adım 4'te gerçek liste ve responsive düzenle doldurulacak.
class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Görevler')),
      body: const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'Görev listesi hazırlanıyor',
        message: 'Bu ekran Adım 4\'te görev listesiyle doldurulacak.',
      ),
    );
  }
}
