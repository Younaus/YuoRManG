import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/task_providers.dart';

/// Yüklenmiş görevlerde başlık/açıklama araması (250 ms debounce).
class TaskSearchField extends ConsumerStatefulWidget {
  const TaskSearchField({this.focusNode, super.key});

  final FocusNode? focusNode;

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

    return TextField(
      key: const Key('tasks.search'),
      controller: _controller,
      focusNode: widget.focusNode,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Görevlerde ara…',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(tooltip: 'Temizle', icon: const Icon(Icons.close, size: 18), onPressed: _clear),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
