import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../tasks/domain/entities/task_query.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../providers/category_providers.dart';

/// Onay alıp kategoriyi siler; seçili kapsam silinen dalda ise "Tüm görevler"e döner.
Future<void> confirmAndDeleteCategory(BuildContext context, WidgetRef ref, Category category) async {
  final hasChildren = category.children.isNotEmpty;
  final strategy = await showDialog<CategoryDeleteStrategy>(
    context: context,
    builder: (_) => _DeleteCategoryDialog(category: category, hasChildren: hasChildren),
  );
  if (strategy == null || !context.mounted) return;

  final tree = ref.read(categoryTreeProvider).value;
  final affected = strategy == CategoryDeleteStrategy.cascade
      ? (tree?.subtreeIds(category.id) ?? [category.id])
      : [category.id];
  final messenger = ScaffoldMessenger.of(context);

  try {
    await ref.read(categoryTreeProvider.notifier).delete(category.id, strategy: strategy);
    final scope = ref.read(selectedScopeProvider);
    if (scope is CategoryScope && affected.contains(scope.categoryId)) {
      ref.read(selectedScopeProvider.notifier).select(const TaskScope.all());
    }
    // Silinen kategorilerdeki görevler kategorisiz kaldı — listeyi tazele.
    ref.invalidate(taskListProvider);
    messenger.showSnackBar(SnackBar(content: Text('"${category.name}" silindi')));
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

class _DeleteCategoryDialog extends StatefulWidget {
  const _DeleteCategoryDialog({required this.category, required this.hasChildren});

  final Category category;
  final bool hasChildren;

  @override
  State<_DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<_DeleteCategoryDialog> {
  CategoryDeleteStrategy _strategy = CategoryDeleteStrategy.lift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('"${widget.category.name}" silinsin mi?'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Görevler silinmez; bu kategorideki görevler kategorisiz olarak kalır.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (widget.hasChildren) ...[
              const SizedBox(height: 12),
              RadioGroup<CategoryDeleteStrategy>(
                groupValue: _strategy,
                onChanged: (v) => setState(() => _strategy = v!),
                child: const Column(
                  children: [
                    RadioListTile(
                      value: CategoryDeleteStrategy.lift,
                      title: Text('Alt kategorileri bir üst seviyeye taşı'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile(
                      value: CategoryDeleteStrategy.cascade,
                      title: Text('Alt kategorileri de sil'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(widget.hasChildren ? _strategy : CategoryDeleteStrategy.cascade),
          child: const Text('Sil'),
        ),
      ],
    );
  }
}
