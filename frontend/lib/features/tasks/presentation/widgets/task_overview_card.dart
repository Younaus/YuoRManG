import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/text_case.dart';
import '../../domain/entities/task.dart';
import '../providers/task_providers.dart';
import 'status_style.dart';

/// Listenin üstündeki "genel bakış" kartı: bugünün tarihi, tamamlanma oranı ve kalan/gecikmiş sayısı.
/// Yalnızca durum filtresi ve arama yokken gösterilir (aksi halde oran anlamsızlaşır).
/// Sayılar yüklenmiş görevlerden hesaplanır; daha fazla sayfa varsa toplamın yanında "+" görünür.
class TaskOverviewCard extends ConsumerWidget {
  const TaskOverviewCard({this.now, super.key});

  /// Test için sabit "şimdi".
  final DateTime? now;

  /// Bu genişlikten itibaren yatay çubuk yerine halka gösterge kullanılır.
  static const wideBreakpoint = 560.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);
    final state = ref.watch(taskListProvider).value;
    if (state == null || state.items.isEmpty || filter.status != null || filter.search.trim().isNotEmpty) {
      return const SizedBox.shrink();
    }
    return _OverviewContent(stats: _Stats.of(state.items, now ?? DateTime.now(), hasMore: state.hasMore));
  }
}

class _Stats {
  const _Stats({
    required this.total,
    required this.done,
    required this.overdue,
    required this.now,
    required this.hasMore,
  });

  factory _Stats.of(List<Task> items, DateTime now, {required bool hasMore}) => _Stats(
    total: items.length,
    done: items.where((t) => t.isDone).length,
    overdue: items.where((t) => t.isOverdue(now)).length,
    now: now,
    hasMore: hasMore,
  );

  final int total;
  final int done;
  final int overdue;
  final DateTime now;
  final bool hasMore;

  int get remaining => total - done;
  double get ratio => total == 0 ? 0 : done / total;
  int get percent => (ratio * 100).round();
  String get totalLabel => hasMore ? '$total+' : '$total';
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({required this.stats});

  final _Stats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = context.surfaces;
    final weekday = DateFormat('EEEE', 'tr_TR').format(stats.now);
    final date = DateFormat('d MMMM', 'tr_TR').format(stats.now);

    final overline = Text(
      toUpperTr('$weekday · Genel bakış'),
      style: theme.textTheme.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w700,
      ),
    );
    final heading = Text('Bugün, $date', style: theme.textTheme.titleLarge);
    final summary = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${stats.done}/${stats.totalLabel} görev tamamlandı',
            style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
          ),
          TextSpan(text: '  ·  ${stats.remaining} kalan'),
        ],
      ),
      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
    );
    final overdueChip = stats.overdue == 0
        ? null
        : Pill(
            label: '${stats.overdue} gecikmiş',
            fg: context.statusColors.overdue,
            bg: context.statusColors.overdueContainer,
            icon: Icons.warning_amber_rounded,
          );
    final percentChip = Pill(
      label: '%${stats.percent}',
      fg: scheme.primary,
      bg: scheme.primary.withValues(alpha: 0.12),
      icon: Icons.bolt_rounded,
    );

    return Container(
      key: const Key('tasks.overview'),
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: surfaces.border),
        boxShadow: surfaces.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= TaskOverviewCard.wideBreakpoint) {
            return Row(
              children: [
                _ProgressRing(ratio: stats.ratio, percent: stats.percent),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [overline, const SizedBox(height: 2), heading, const SizedBox(height: 4), summary],
                  ),
                ),
                if (overdueChip != null) ...[const SizedBox(width: 12), overdueChip],
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [overline, const SizedBox(height: 2), heading],
                    ),
                  ),
                  const SizedBox(width: 8),
                  percentChip,
                ],
              ),
              const SizedBox(height: 14),
              summary,
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: stats.ratio, minHeight: 8),
              ),
              if (overdueChip != null) ...[const SizedBox(height: 12), overdueChip],
            ],
          );
        },
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.ratio, required this.percent});

  final double ratio;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.square(
      dimension: 64,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(value: ratio, strokeWidth: 6, strokeCap: StrokeCap.round),
          Center(
            child: Text(
              '%$percent',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
