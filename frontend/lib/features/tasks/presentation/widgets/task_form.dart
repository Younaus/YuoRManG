import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_colors.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_draft.dart';
import '../../domain/entities/task_query.dart';
import '../../domain/entities/task_status.dart';
import '../providers/task_providers.dart';
import 'status_style.dart';

/// Seçili kategoriyi varsayılan alarak yeni görev formunu açar (FAB, yan menü, Ctrl+N).
Future<bool?> showNewTaskForm(BuildContext context, WidgetRef ref) {
  final scope = ref.read(selectedScopeProvider);
  return showTaskForm(context, defaultCategoryId: scope is CategoryScope ? scope.categoryId : null);
}

/// Görev oluşturma/düzenleme: mobilde tam yükseklikte alt sayfa, geniş ekranda diyalog.
/// Kaydedilirse `true` döner.
Future<bool?> showTaskForm(BuildContext context, {Task? task, String? defaultCategoryId}) {
  final form = TaskForm(task: task, defaultCategoryId: defaultCategoryId);
  if (context.windowSize == WindowSize.compact) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: form,
      ),
    );
  }
  return showDialog<bool>(
    context: context,
    builder: (_) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: form),
    ),
  );
}

class TaskForm extends ConsumerStatefulWidget {
  const TaskForm({this.task, this.defaultCategoryId, super.key});

  final Task? task;
  final String? defaultCategoryId;

  @override
  ConsumerState<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.task?.title);
  late final _description = TextEditingController(text: widget.task?.description);
  late DateTime? _dueDate = widget.task?.dueDate;
  late String? _categoryId = widget.task != null ? widget.task!.categoryId : widget.defaultCategoryId;
  late TaskStatus _status = widget.task?.status ?? TaskStatus.todo;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.task != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dueDate ?? now;
    final first = DateTime(now.year - 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: initial.isBefore(first) ? initial : first,
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: 'Bitiş tarihi',
    );
    if (picked != null) setState(() => _dueDate = endOfDay(picked));
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final draft = TaskDraft(
      title: _title.text,
      description: _description.text,
      status: _status,
      dueDate: _dueDate,
      categoryId: _categoryId,
    );
    final controller = ref.read(taskListProvider.notifier);
    try {
      if (_isEdit) {
        await controller.edit(widget.task!, draft);
      } else {
        await controller.create(draft);
      }
      if (mounted) Navigator.of(context).pop(true);
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
    final tree = ref.watch(categoryTreeProvider).value;
    final categories = tree?.flattened ?? const [];
    // Silinmiş bir kategoriye işaret ediyorsa "Kategorisiz" göster.
    final categoryValue = tree?[_categoryId] != null ? _categoryId : null;

    final dueField = InkWell(
      key: const Key('taskForm.dueDate'),
      borderRadius: BorderRadius.circular(8),
      onTap: _pickDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Bitiş tarihi',
          prefixIcon: const Icon(Icons.event_outlined, size: 20),
          suffixIcon: _dueDate == null
              ? null
              : IconButton(
                  tooltip: 'Tarihi kaldır',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _dueDate = null),
                ),
        ),
        child: Text(
          _dueDate == null ? 'Tarih yok' : relativeDayOrLong(_dueDate!),
          overflow: TextOverflow.ellipsis,
          style: _dueDate == null ? TextStyle(color: theme.colorScheme.onSurfaceVariant) : null,
        ),
      ),
    );

    final categoryField = DropdownButtonFormField<String?>(
      key: const Key('taskForm.category'),
      initialValue: categoryValue,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Kategori', prefixIcon: Icon(Icons.folder_outlined, size: 20)),
      selectedItemBuilder: (_) => [
        const Text('Kategorisiz'),
        for (final f in categories) Text(f.category.name, overflow: TextOverflow.ellipsis),
      ],
      items: [
        const DropdownMenuItem(value: null, child: Text('Kategorisiz')),
        for (final f in categories)
          DropdownMenuItem(
            value: f.category.id,
            child: Padding(
              padding: EdgeInsets.only(left: f.depth * 16.0),
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
      onChanged: (v) => setState(() => _categoryId = v),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
      },
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_isEdit ? 'Görevi düzenle' : 'Yeni görev', style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('taskForm.title'),
                controller: _title,
                autofocus: !_isEdit,
                maxLength: 200,
                buildCounter: _hideCounter,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Başlık', hintText: 'Ne yapılması gerekiyor?'),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Başlık gerekli' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('taskForm.description'),
                controller: _description,
                minLines: 3,
                maxLines: 8,
                maxLength: 5000,
                buildCounter: _hideCounter,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Ayrıntılar, notlar…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, c) => c.maxWidth >= 440
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: dueField),
                          const SizedBox(width: 12),
                          Expanded(child: categoryField),
                        ],
                      )
                    : Column(children: [dueField, const SizedBox(height: 14), categoryField]),
              ),
              const SizedBox(height: 18),
              Text('Durum', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<TaskStatus>(
                key: const Key('taskForm.status'),
                showSelectedIcon: false,
                segments: [
                  for (final s in TaskStatus.values)
                    ButtonSegment(
                      value: s,
                      // Nokta etiketin içinde: dar ekranda "Devam ediyor" sığsın diye ikon boşluğu kullanılmaz.
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(color: context.statusColors.of(s).fg, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(s.label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                ],
                selected: {_status},
                onSelectionChanged: (s) => setState(() => _status = s.first),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('İptal')),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('taskForm.submit'),
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isEdit ? 'Kaydet' : 'Oluştur'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget? _hideCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) =>
      null;
}

/// "Bugün / Yarın" gibi yakın tarihlerde kısa, diğerlerinde uzun biçim.
String relativeDayOrLong(DateTime date) {
  final diff = calendarDaysBetween(DateTime.now(), date);
  return diff.abs() <= 1 ? '${relativeDayLabel(date)} · ${longDateLabel(date)}' : longDateLabel(date);
}
