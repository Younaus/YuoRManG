import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_tree.dart';
import '../../domain/repositories/category_repository.dart';
import '../providers/category_providers.dart';
import 'category_colors.dart';

/// Kategori oluşturma veya düzenleme (ad, üst kategori = taşıma, renk) penceresi.
/// [category] verilirse düzenleme modundadır. Kaydedilen kategoriyi döner.
Future<Category?> showCategoryFormDialog(BuildContext context, {String? parentId, Category? category}) {
  return showDialog<Category>(
    context: context,
    builder: (_) => _CategoryFormDialog(parentId: parentId, category: category),
  );
}

class _CategoryFormDialog extends ConsumerStatefulWidget {
  const _CategoryFormDialog({this.parentId, this.category});

  final String? parentId;
  final Category? category;

  @override
  ConsumerState<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  // Düzenlemede mevcut ad tamamen seçili gelir; yazınca yerine geçer.
  late final _name = TextEditingController(text: widget.category?.name)
    ..selection = TextSelection(baseOffset: 0, extentOffset: widget.category?.name.length ?? 0);
  late String? _parentId = widget.category != null ? widget.category!.parentId : widget.parentId;
  late String _color = widget.category?.color ?? categoryPalette.first;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.category != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final controller = ref.read(categoryTreeProvider.notifier);
    try {
      final Category saved;
      if (_isEdit) {
        final original = widget.category!;
        final name = _name.text.trim();
        final nameChanged = name != original.name;
        final colorChanged = _color != original.color;
        final parentChanged = _parentId != original.parentId;
        if (!nameChanged && !colorChanged && !parentChanged) {
          Navigator.of(context).pop(original);
          return;
        }
        saved = await controller.updateCategory(
          original.id,
          name: nameChanged ? name : null,
          color: colorChanged ? _color : null,
          parent: parentChanged ? ParentChange(_parentId) : null,
        );
      } else {
        saved = await controller.create(name: _name.text, parentId: _parentId, color: _color);
      }
      if (mounted) Navigator.of(context).pop(saved);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.code == 'CONFLICT' ? 'Bu seviyede aynı adda bir kategori zaten var.' : e.message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tree = ref.watch(categoryTreeProvider).value;
    // Düzenlemede kategori kendi altına / alt dalına taşınamaz.
    final List<FlatCategory> options =
        tree == null ? const [] : (_isEdit ? tree.moveTargetsFor(widget.category!.id) : tree.flattened);

    return AlertDialog(
      title: Text(
        _isEdit
            ? 'Kategoriyi düzenle'
            : widget.parentId == null
                ? 'Yeni kategori'
                : 'Yeni alt kategori',
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('categoryForm.name'),
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Ad'),
                maxLength: 100,
                buildCounter: (_, {required currentLength, required isFocused, required maxLength}) => null,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Ad gerekli' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: tree?[_parentId] != null ? _parentId : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Üst kategori'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Yok (en üst seviye)')),
                  for (final f in options)
                    DropdownMenuItem(
                      value: f.category.id,
                      child: Padding(
                        padding: EdgeInsets.only(left: f.depth * 14.0),
                        child: Text(f.category.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _parentId = v),
              ),
              const SizedBox(height: 18),
              Text('Renk', style: theme.textTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final hex in categoryPalette)
                    _ColorSwatch(hex: hex, selected: hex == _color, onTap: () => setState(() => _color = hex)),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('İptal')),
        FilledButton(
          key: const Key('categoryForm.submit'),
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEdit ? 'Kaydet' : 'Oluştur'),
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.hex, required this.selected, required this.onTap});

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(hex)!;
    return Semantics(
      button: true,
      selected: selected,
      label: hex,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 30,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: selected ? color : Colors.transparent, width: 2),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
        ),
      ),
    );
  }
}
