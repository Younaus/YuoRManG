import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/desktop/global_hotkey_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_colors.dart';
import '../../domain/entities/task.dart';
import '../../domain/quick_capture.dart';
import '../providers/task_providers.dart';

/// Sade "Hızlı Görev Ekle" diyaloğu. Kaydedilirse oluşturulan görevi, `Esc`/İptal ile `null` döner.
Future<Task?> showQuickCaptureDialog(BuildContext context) => showDialog<Task>(
  context: context,
  builder: (_) =>
      const Dialog(key: Key('quickCapture.dialog'), clipBehavior: Clip.antiAlias, child: QuickCaptureForm()),
);

class QuickCaptureForm extends ConsumerStatefulWidget {
  const QuickCaptureForm({this.now, super.key});

  /// Test için sabit "şimdi".
  final DateTime Function()? now;

  @override
  ConsumerState<QuickCaptureForm> createState() => _QuickCaptureFormState();
}

class _QuickCaptureFormState extends ConsumerState<QuickCaptureForm> {
  final _title = TextEditingController();
  QuickDue _due = QuickDue.none;
  String? _categoryId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final draft = quickCaptureDraft(
      title: _title.text,
      due: _due,
      categoryId: _categoryId,
      now: (widget.now ?? DateTime.now)(),
    );
    if (draft == null) {
      setState(() => _error = 'Başlık gerekli');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final task = await ref.read(taskListProvider.notifier).create(draft);
      if (mounted) Navigator.of(context).pop(task);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Görev kaydedilemedi. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tree = ref.watch(categoryTreeProvider).value;
    final categories = tree?.flattened ?? const [];
    final categoryValue = tree?[_categoryId] != null ? _categoryId : null;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: CallbackShortcuts(
        // Odak çiplerde/düğmelerdeyken de Enter kaydeder (Esc → Dialog kapanır).
        bindings: {const SingleActivator(LogicalKeyboardKey.enter): _save},
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Hızlı görev', style: theme.textTheme.titleMedium)),
                  Text(
                    quickCaptureShortcutLabel,
                    style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('quickCapture.title'),
                controller: _title,
                autofocus: true,
                maxLength: 200,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(hintText: 'Ne yapılması gerekiyor?', counterText: '', errorText: _error),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final due in QuickDue.values)
                    ChoiceChip(
                      key: Key('quickCapture.due.${due.name}'),
                      label: Text(due.label),
                      selected: _due == due,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _due = due),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: const Key('quickCapture.category'),
                initialValue: categoryValue,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.folder_outlined, size: 20)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Kategorisiz')),
                  for (final f in categories)
                    DropdownMenuItem(
                      value: f.category.id,
                      child: Padding(
                        padding: EdgeInsets.only(left: f.depth * 14.0),
                        child: Row(
                          children: [
                            CategoryDot(hex: f.category.color, size: 8),
                            const SizedBox(width: 10),
                            Flexible(child: Text(f.category.name, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ),
                ],
                selectedItemBuilder: (_) => [
                  const Text('Kategorisiz'),
                  for (final f in categories) Text(f.category.name, overflow: TextOverflow.ellipsis),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Enter kaydet · Esc iptal',
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('İptal')),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('quickCapture.save'),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
