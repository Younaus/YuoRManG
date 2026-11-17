import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/task_providers.dart';

/// Sunucu tarafı başlık araması (`q`, 250 ms debounce).
class TaskSearchField extends ConsumerStatefulWidget {
  const TaskSearchField({this.focusNode, this.shortcutHint, super.key});

  final FocusNode? focusNode;

  /// Boşken sağda gösterilecek klavye kısayolu (masaüstü), ör. "Ctrl F".
  final String? shortcutHint;

  @override
  ConsumerState<TaskSearchField> createState() => _TaskSearchFieldState();
}

class _TaskSearchFieldState extends ConsumerState<TaskSearchField> {
  late final _controller = TextEditingController(text: ref.read(taskFilterProvider).search);
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // temizle butonunun görünürlüğü
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) ref.read(taskFilterProvider.notifier).setSearch(value);
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {});
    ref.read(taskFilterProvider.notifier).setSearch('');
  }

  @override
  Widget build(BuildContext context) {
    // Filtre dışarıdan sıfırlanırsa (ör. kullanıcı değişti) alanı da temizle.
    ref.listen(taskFilterProvider.select((f) => f.search), (_, next) {
      if (next.isEmpty && _controller.text.isNotEmpty && !(_debounce?.isActive ?? false)) _controller.clear();
    });

    final theme = Theme.of(context);
    final Widget? suffix = _controller.text.isNotEmpty
        ? IconButton(tooltip: 'Temizle', icon: const Icon(Icons.close_rounded, size: 18), onPressed: _clear)
        : widget.shortcutHint == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Center(widthFactor: 1, child: _KeyHint(widget.shortcutHint!)),
              );

    return TextField(
      key: const Key('tasks.search'),
      controller: _controller,
      focusNode: widget.focusNode,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Görevlerde ara…',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

/// Klavye kısayolu ipucu ("Ctrl F").
class _KeyHint extends StatelessWidget {
  const _KeyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(text, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}
