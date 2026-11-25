import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand.dart';
import '../../../tasks/presentation/widgets/sync_widgets.dart';
import '../../domain/entities/category_tree.dart';
import '../providers/category_providers.dart';
import '../widgets/category_colors.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/category_tree_panel.dart';

/// Mobil/tablet "Kategoriler" sekmesi: hiyerarşi özeti + ağaç. Ağaçtan seçim yapınca görevler sekmesine geçer.
/// Aşağı çekince (veya geniş ekranda yenile düğmesiyle) kategoriler ve görevler birlikte yenilenir.
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = context.windowSize == WindowSize.compact;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: AppTitleBlock(title: 'Kategoriler', showLogo: isCompact),
        actions: [if (!isCompact) const SyncButton(), const SizedBox(width: 8)],
      ),
      floatingActionButton: AppFab(
        key: const Key('categories.fab'),
        tooltip: 'Yeni kategori',
        icon: Icons.create_new_folder_outlined,
        onPressed: () => showCategoryFormDialog(context),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: RefreshIndicator(
              onRefresh: () => refreshAllWithFeedback(context, ref),
              child: CategoryTreePanel(
                highlightSelection: false,
                header: const _HierarchyOverview(),
                onScopeSelected: (_) => context.go(AppRoutes.tasks),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Hiyerarşi özeti": ana/alt kategori sayıları ve ana kategorilerin (alt dallarıyla) dağılım çubuğu.
class _HierarchyOverview extends ConsumerWidget {
  const _HierarchyOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tree = ref.watch(categoryTreeProvider).value ?? CategoryTree.empty;
    if (tree.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = context.surfaces;
    final roots = tree.roots;
    final subCount = tree.length - roots.length;
    final weights = [for (final r in roots) tree.subtreeIds(r.id).length];

    return Container(
      key: const Key('categories.overview'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: surfaces.border),
        boxShadow: surfaces.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(text: 'Hiyerarşi özeti'),
          const SizedBox(height: 4),
          Text('${roots.length} ana kategori · $subCount alt kategori', style: theme.textTheme.titleMedium),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < roots.length; i++) ...[
                    if (i > 0) SizedBox(width: 3, child: ColoredBox(color: surfaces.card)),
                    Expanded(
                      flex: weights[i],
                      child: ColoredBox(color: colorFromHex(roots[i].color) ?? scheme.outline),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (var i = 0; i < roots.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CategoryDot(hex: roots[i].color, size: 8),
                    const SizedBox(width: 6),
                    Text(
                      '${roots[i].name} (${weights[i]})',
                      style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
