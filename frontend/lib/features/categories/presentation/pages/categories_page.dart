import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/category_tree_panel.dart';

/// Mobil/tablet "Kategoriler" sekmesi: ağaçtan seçim yapınca görevler sekmesine geçer.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategoriler'),
        actions: [
          IconButton(
            tooltip: 'Yeni kategori',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => showCategoryFormDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: CategoryTreePanel(
              highlightSelection: false,
              onScopeSelected: (_) => context.go(AppRoutes.tasks),
            ),
          ),
        ),
      ),
    );
  }
}
