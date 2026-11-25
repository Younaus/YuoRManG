import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sync_providers.dart';

/// Kategorileri ve görevleri birlikte yeniler; başarısız olursa kısa bir uyarı gösterir.
/// (Aşağı çekip yenileme, yenile düğmesi ve F5 bunu kullanır.)
Future<void> refreshAllWithFeedback(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await ref.read(syncProvider.notifier).refreshAll();
  if (!ok) {
    messenger?.showSnackBar(const SnackBar(content: Text('Yenilenemedi. Bağlantınızı kontrol edip tekrar deneyin.')));
  }
}

/// Uygulama arka plandan öne geldiğinde (mobilde geri dönüş, masaüstünde pencereye odaklanma)
/// kategorileri ve görevleri yeniler — 5 sn bekleme süresiyle.
class SyncOnResume extends ConsumerStatefulWidget {
  const SyncOnResume({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SyncOnResume> createState() => _SyncOnResumeState();
}

class _SyncOnResumeState extends ConsumerState<SyncOnResume> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => ref.read(syncProvider.notifier).refreshOnResume());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Uygulama açılırken oluşsun: bekleme süresi ilk yüklemeden itibaren sayılır.
    ref.listen(syncProvider, (_, _) {});
    return widget.child;
  }
}

/// Masaüstü üst çubuğundaki "Yenile" düğmesi: kategoriler + görevler.
class SyncButton extends ConsumerWidget {
  const SyncButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshing = ref.watch(syncProvider.select((s) => s.refreshing));
    return IconButton(
      key: const Key('tasks.refresh'),
      tooltip: 'Yenile (F5)',
      onPressed: refreshing ? null : () => refreshAllWithFeedback(context, ref),
      icon: refreshing
          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.refresh_rounded),
    );
  }
}
