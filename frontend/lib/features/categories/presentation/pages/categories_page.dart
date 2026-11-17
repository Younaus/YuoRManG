import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';

/// Kategori ağacı — sonraki adımlarda doldurulacak.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategoriler')),
      body: const EmptyState(
        icon: Icons.folder_outlined,
        title: 'Kategoriler',
        message: 'Hiyerarşik kategori ağacı sonraki adımlarda eklenecek.',
      ),
    );
  }
}
