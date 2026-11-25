import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/offline_sync_providers.dart';
import '../providers/sync_providers.dart';
import 'status_style.dart';

/// Uygulamanın üstünde ince "Çevrimdışı mod" şeridi; bekleyen işlem sayısını da gösterir.
/// Ağaç yapısı şerit görünse de görünmese de aynıdır (router durumu korunur).
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Oturum kapanınca önbelleği temizleyen dinleyici uygulama boyunca yaşasın.
    ref.watch(offlineSessionGuardProvider);
    final state = ref.watch(offlineSyncProvider);
    final visible = state.offline || state.pending > 0;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: visible ? _Strip(state: state) : const SizedBox(width: double.infinity),
        ),
        Expanded(
          // Şerit durum çubuğu boşluğunu kendisi kullanır; altındaki ekranlar tekrar eklemesin.
          child: MediaQuery.removePadding(context: context, removeTop: visible, child: child),
        ),
      ],
    );
  }
}

class _Strip extends ConsumerWidget {
  const _Strip({required this.state});

  final OfflineState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.statusColors;
    final pending = state.pending;
    final (IconData icon, String text) = state.offline
        ? (
            Icons.cloud_off_rounded,
            'Çevrimdışı mod · kayıtlı veriler gösteriliyor${pending > 0 ? ' · $pending değişiklik bekliyor' : ''}',
          )
        : state.syncing
        ? (Icons.cloud_sync_rounded, 'Değişiklikler gönderiliyor…')
        : (Icons.cloud_upload_outlined, '$pending değişiklik gönderilmeyi bekliyor');

    return Material(
      key: const Key('offline.banner'),
      color: colors.inProgressContainer,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 30,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(icon, size: 16, color: colors.inProgress),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!state.syncing)
                  TextButton(
                    key: const Key('offline.retry'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: colors.inProgress,
                    ),
                    onPressed: () => ref.read(syncProvider.notifier).refreshAll(),
                    child: Text(state.offline ? 'Tekrar dene' : 'Gönder'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
