import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand.dart';

import '../../../tasks/domain/entities/task_query.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../domain/entities/category.dart';
import '../providers/category_providers.dart';
import 'category_actions.dart';
import 'category_colors.dart';
import 'category_form_dialog.dart';

/// "Tüm görevler / Kategorisiz" kısayolları + hiyerarşik kategori ağacı.
/// Masaüstü yan menüsü, mobil çekmece ve Kategoriler sekmesi bu paneli paylaşır.
class CategoryTreePanel extends ConsumerStatefulWidget {
  const CategoryTreePanel({
    this.onScopeSelected,
    this.highlightSelection = true,
    this.enableDragAndDrop = false,
    this.header,
    super.key,
  });

  /// Listenin en üstünde, panelle birlikte kayan içerik (ör. özet kartı).
  final Widget? header;

  /// Seçimden sonra (ör. çekmeceyi kapatmak / görevler sekmesine geçmek için).
  final ValueChanged<TaskScope>? onScopeSelected;

  /// Görevler sekmesi dışındayken seçimi vurgulamamak için.
  final bool highlightSelection;

  /// Sürükle-bırak ile taşıma (masaüstü yan menü). Dokunmatikte kaydırmayla çakışmasın diye kapalı.
  final bool enableDragAndDrop;

  @override
  ConsumerState<CategoryTreePanel> createState() => _CategoryTreePanelState();
}

class _CategoryTreePanelState extends ConsumerState<CategoryTreePanel> {
  /// Sürüklenmekte olan kategori ("en üst seviye" bırakma alanını göstermek için).
  Category? _dragging;

  void _setDragging(Category? c) {
    if (mounted && _dragging != c) setState(() => _dragging = c);
  }

  @override
  Widget build(BuildContext context) {
    final scope = ref.watch(selectedScopeProvider);
    final treeAsync = ref.watch(categoryTreeProvider);
    final collapsed = ref.watch(collapsedCategoriesProvider);
    final tree = treeAsync.value;

    void select(TaskScope s) {
      ref.read(selectedScopeProvider.notifier).select(s);
      widget.onScopeSelected?.call(s);
    }

    bool isSelected(TaskScope s) => widget.highlightSelection && scope == s;

    List<Widget> buildNodes(List<Category> nodes, int depth) => [
          for (final c in nodes) ...[
            _withDragAndDrop(
              c,
              _CategoryTile(
                category: c,
                depth: depth,
                selected: isSelected(TaskScope.category(c.id)),
                expanded: !collapsed.contains(c.id),
                onTap: () => select(TaskScope.category(c.id)),
                onToggleExpanded: () => ref.read(collapsedCategoriesProvider.notifier).toggle(c.id),
              ),
            ),
            if (c.children.isNotEmpty && !collapsed.contains(c.id)) ...buildNodes(c.children, depth + 1),
          ],
        ];

    final showRootDrop = widget.enableDragAndDrop && _dragging?.parentId != null && tree != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      children: [
        if (widget.header != null) ...[widget.header!, const SizedBox(height: 16)],
        const SectionLabel(text: 'Görünümler', padding: EdgeInsets.fromLTRB(12, 8, 12, 6)),
        _ScopeTile(
          icon: Icons.inbox_outlined,
          selectedIcon: Icons.inbox,
          label: 'Tüm görevler',
          selected: isSelected(const TaskScope.all()),
          onTap: () => select(const TaskScope.all()),
        ),
        _ScopeTile(
          icon: Icons.label_off_outlined,
          selectedIcon: Icons.label_off,
          label: 'Kategorisiz',
          selected: isSelected(const TaskScope.uncategorized()),
          onTap: () => select(const TaskScope.uncategorized()),
        ),
        const SizedBox(height: 18),
        SectionLabel(
          text: 'Kategoriler',
          padding: const EdgeInsets.only(left: 12),
          trailing: IconButton(
            key: const Key('categories.add'),
            tooltip: 'Yeni kategori',
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => showCategoryFormDialog(context),
          ),
        ),
        if (showRootDrop)
          _RootDropZone(onAccept: (dragged) => moveCategory(context, ref, dragged, null)),
        ...treeAsync.when(
          skipLoadingOnReload: true,
          data: (tree) => tree.isEmpty
              ? [const _Hint('Henüz kategori yok. Görevlerinizi gruplamak için + ile ekleyin.')]
              : buildNodes(tree.roots, 0),
          loading: () => const [
            Padding(padding: EdgeInsets.symmetric(vertical: 16), child: LinearProgressIndicator()),
          ],
          error: (e, _) => [
            const _Hint('Kategoriler yüklenemedi.'),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => ref.invalidate(categoryTreeProvider), child: const Text('Tekrar dene')),
            ),
          ],
        ),
      ],
    );
  }

  /// Satırı hem sürüklenebilir hem de "buraya bırak → altına taşı" hedefi yapar.
  Widget _withDragAndDrop(Category c, Widget tile) {
    final tree = ref.read(categoryTreeProvider).value;
    if (!widget.enableDragAndDrop || tree == null) return tile;
    final scheme = Theme.of(context).colorScheme;

    return Draggable<Category>(
      key: Key('category.drag.${c.id}'),
      data: c,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => _setDragging(c),
      onDragEnd: (_) => _setDragging(null),
      feedback: _DragFeedback(category: c),
      childWhenDragging: Opacity(opacity: 0.4, child: tile),
      child: DragTarget<Category>(
        // Kendisi, kendi alt dalı ya da zaten bulunduğu üst kategori kabul edilmez.
        onWillAcceptWithDetails: (d) => d.data.parentId != c.id && tree.canMoveTo(d.data.id, c.id),
        onAcceptWithDetails: (d) => moveCategory(context, ref, d.data, c.id),
        builder: (context, candidates, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: candidates.isNotEmpty ? scheme.primary.withValues(alpha: 0.10) : Colors.transparent,
            border: Border.all(color: candidates.isNotEmpty ? scheme.primary : Colors.transparent, width: 1.5),
          ),
          child: tile,
        ),
      ),
    );
  }
}

class _RootDropZone extends StatelessWidget {
  const _RootDropZone({required this.onAccept});

  final ValueChanged<Category> onAccept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DragTarget<Category>(
      key: const Key('categories.rootDrop'),
      onWillAcceptWithDetails: (d) => d.data.parentId != null,
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (context, candidates, _) {
        final active = candidates.isNotEmpty;
        final color = active ? scheme.primary : scheme.onSurfaceVariant;
        return Container(
          height: 40,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: active ? scheme.primary.withValues(alpha: 0.10) : Colors.transparent,
            border: Border.all(color: active ? scheme.primary : scheme.outlineVariant, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.vertical_align_top, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'En üst seviyeye taşı',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CategoryDot(hex: category.color),
            const SizedBox(width: 10),
            Text(category.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}

/// Seçilebilir satırların ortak görünümü: seçiliyken dolu indigo zemin.
class _SelectableRow extends StatelessWidget {
  const _SelectableRow({required this.selected, required this.onTap, required this.child, this.onLongPress});

  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(AppTheme.radiusSm));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: selected
              ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 3))]
              : null,
        ),
        child: Material(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            onLongPress: onLongPress,
            child: SizedBox(height: 42, child: child),
          ),
        ),
      ),
    );
  }
}

class _ScopeTile extends StatelessWidget {
  const _ScopeTile({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant;
    return _SelectableRow(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(selected ? selectedIcon : icon, size: 20, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected ? fg : theme.colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends ConsumerStatefulWidget {
  const _CategoryTile({
    required this.category,
    required this.depth,
    required this.selected,
    required this.expanded,
    required this.onTap,
    required this.onToggleExpanded,
  });

  final Category category;
  final int depth;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onToggleExpanded;

  @override
  ConsumerState<_CategoryTile> createState() => _CategoryTileState();
}

enum _CategoryAction { edit, addChild, delete }

class _CategoryTileState extends ConsumerState<_CategoryTile> {
  bool _hovered = false;
  final _menuKey = GlobalKey<PopupMenuButtonState<_CategoryAction>>();

  void _onAction(_CategoryAction action) {
    switch (action) {
      case _CategoryAction.edit:
        showCategoryFormDialog(context, category: widget.category);
      case _CategoryAction.addChild:
        showCategoryFormDialog(context, parentId: widget.category.id);
      case _CategoryAction.delete:
        confirmAndDeleteCategory(context, ref, widget.category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.category;
    final hasChildren = c.children.isNotEmpty;
    final scheme = theme.colorScheme;
    final fg = widget.selected ? scheme.onPrimary : scheme.onSurface;
    final muted = widget.selected ? scheme.onPrimary.withValues(alpha: 0.8) : scheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: _SelectableRow(
        selected: widget.selected,
        onTap: widget.onTap,
        onLongPress: () => _menuKey.currentState?.showButtonMenu(),
        child: Row(
          children: [
            SizedBox(width: 4 + widget.depth * 16.0),
            SizedBox(
              width: 28,
              child: hasChildren
                  ? IconButton(
                      tooltip: widget.expanded ? 'Daralt' : 'Genişlet',
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      icon: AnimatedRotation(
                        turns: widget.expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(Icons.chevron_right, color: muted),
                      ),
                      onPressed: widget.onToggleExpanded,
                    )
                  : null,
            ),
            const SizedBox(width: 2),
            _CategoryIcon(hex: c.color, onPrimary: widget.selected),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                c.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            // Menü: fareyle üzerine gelince / seçiliyken görünür; dokunmatikte uzun basınca açılır.
            Opacity(
              opacity: _hovered || widget.selected ? 1 : 0,
              child: PopupMenuButton<_CategoryAction>(
                key: _menuKey,
                tooltip: 'Kategori işlemleri',
                iconSize: 18,
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_horiz, color: muted),
                onSelected: _onAction,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    key: Key('category.menu.edit'),
                    value: _CategoryAction.edit,
                    child: ListTile(leading: Icon(Icons.drive_file_move_outline), title: Text('Düzenle / taşı')),
                  ),
                  PopupMenuItem(
                    value: _CategoryAction.addChild,
                    child: ListTile(leading: Icon(Icons.create_new_folder_outlined), title: Text('Alt kategori ekle')),
                  ),
                  PopupMenuItem(
                    value: _CategoryAction.delete,
                    child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Sil')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kategori rengine boyanmış küçük klasör karosu.
class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.hex, required this.onPrimary});

  final String? hex;

  /// Seçili (indigo zeminli) satırda beyaz tonlarda çizilir.
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = onPrimary ? scheme.onPrimary : (colorFromHex(hex) ?? scheme.outline);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withValues(alpha: onPrimary ? 0.20 : 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs + 1),
      ),
      child: Icon(Icons.folder_rounded, size: 15, color: color),
    );
  }
}
