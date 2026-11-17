import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/category.dart';
import '../providers/category_providers.dart';
import 'category_colors.dart';

/// Yeni (alt) kategori oluşturma penceresi. Oluşturulan kategoriyi döner.
Future<Category?> showCategoryFormDialog(BuildContext context, {String? parentId}) {
  return showDialog<Category>(context: context, builder: (_) => _CategoryFormDialog(parentId: parentId));
}

class _CategoryFormDialog extends ConsumerStatefulWidget {
  const _CategoryFormDialog({this.parentId});

  final String? parentId;

  @override
  ConsumerState<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late String? _parentId = widget.parentId;
  String _color = categoryPalette.first;
  bool _saving = false;
  String? _error;

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
    try {
      final created = await ref
          .read(categoryTreeProvider.notifier)
          .create(name: _name.text, parentId: _parentId, color: _color);
      if (mounted) Navigator.of(context).pop(created);
    } on ApiException catch (e) {
      setState(() => _error = e.code == 'CONFLICT' ? 'Bu seviyede aynı adda bir kategori zaten var.' : e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tree = ref.watch(categoryTreeProvider).value;
    final options = tree?.flattened ?? const [];

    return AlertDialog(
      title: Text(widget.parentId == null ? 'Yeni kategori' : 'Yeni alt kategori'),
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
              : const Text('Oluştur'),
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
