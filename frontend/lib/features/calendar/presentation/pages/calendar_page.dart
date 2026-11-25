import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../../core/widgets/brand.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/domain/entities/task_status.dart';
import '../../../tasks/presentation/providers/calendar_providers.dart';
import '../../../tasks/presentation/widgets/status_style.dart';
import '../../../tasks/presentation/widgets/sync_widgets.dart';
import '../../../tasks/presentation/widgets/task_card.dart';
import '../../../tasks/presentation/widgets/task_form.dart';
import '../../domain/calendar_grouping.dart';

/// Takvim görünümü: bitiş tarihli görevler günlere işaretlenir; seçili günün görevleri
/// takvimin altında (geniş ekranda sağ panelde) listelenir.
class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  /// Bu genişlikten itibaren gün paneli takvimin sağında.
  static const sidePanelBreakpoint = 860.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = context.windowSize;
    final isExpanded = size == WindowSize.expanded;
    final isCompact = size == WindowSize.compact;
    final loading = ref.watch(calendarTasksProvider.select((s) => s.isLoading));

    return Scaffold(
      appBar: isExpanded
          ? null
          : AppBar(
              toolbarHeight: 64,
              title: AppTitleBlock(title: 'Takvim', showLogo: isCompact),
              actions: [if (!isCompact) const SyncButton(), const SizedBox(width: 8)],
            ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isExpanded) const _DesktopHeader(),
            SizedBox(height: 2, child: loading ? const LinearProgressIndicator() : null),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final pad = isCompact ? 12.0 : 24.0;
                  if (c.maxWidth >= sidePanelBreakpoint) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(pad, 8, pad, pad),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(child: SingleChildScrollView(child: _CalendarCard())),
                          SizedBox(width: pad),
                          const SizedBox(width: 380, child: _DayTasksPanel()),
                        ],
                      ),
                    );
                  }
                  // Dar ekran: takvim + günün görevleri tek kaydırılan sayfa.
                  return ListView(
                    padding: EdgeInsets.fromLTRB(pad, 4, pad, 104),
                    children: const [
                      _CalendarCard(compact: true),
                      SizedBox(height: 16),
                      _DayTasksPanel(embedded: true),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bitiş tarihine göre planlama',
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text('Takvim', style: theme.textTheme.headlineSmall),
              ],
            ),
          ),
          const SyncButton(),
        ],
      ),
    );
  }
}

class _CalendarCard extends ConsumerWidget {
  const _CalendarCard({this.compact = false});

  final bool compact;

  static const _formats = {
    CalendarFormat.month: 'Ay',
    CalendarFormat.twoWeeks: '2 Hafta',
    CalendarFormat.week: 'Hafta',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final focused = ref.watch(calendarFocusedDayProvider);
    final selected = ref.watch(calendarSelectedDayProvider);
    final format = ref.watch(calendarFormatProvider);
    final byDay = ref.watch(calendarTasksByDayProvider);
    final now = DateTime.now();

    void goToday() {
      ref.read(calendarSelectedDayProvider.notifier).select(now);
      ref.read(calendarFocusedDayProvider.notifier).focus(now);
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<CalendarFormat>(
                      key: const Key('calendar.format'),
                      showSelectedIcon: false,
                      segments: [
                        for (final e in _formats.entries)
                          ButtonSegment(
                            value: e.key,
                            label: Text(e.value, style: const TextStyle(fontSize: 13)),
                          ),
                      ],
                      selected: {format},
                      onSelectionChanged: (s) => ref.read(calendarFormatProvider.notifier).set(s.first),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  key: const Key('calendar.today'),
                  onPressed: goToday,
                  icon: const Icon(Icons.today_outlined, size: 18),
                  label: const Text('Bugün'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TableCalendar<Task>(
              key: const Key('calendar.table'),
              locale: 'tr_TR',
              firstDay: DateTime(2020),
              lastDay: DateTime(2035, 12, 31),
              focusedDay: focused,
              calendarFormat: format,
              availableCalendarFormats: _formats,
              startingDayOfWeek: StartingDayOfWeek.monday,
              rowHeight: compact ? 44 : 52,
              selectedDayPredicate: (day) => isSameDay(day, selected),
              eventLoader: (day) => byDay[calendarDay(day)] ?? const [],
              onDaySelected: (day, focusedDay) {
                ref.read(calendarSelectedDayProvider.notifier).select(day);
                ref.read(calendarFocusedDayProvider.notifier).focus(focusedDay);
              },
              onPageChanged: (day) => ref.read(calendarFocusedDayProvider.notifier).focus(day),
              onFormatChanged: (f) => ref.read(calendarFormatProvider.notifier).set(f),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: theme.textTheme.titleMedium!,
                leftChevronIcon: Icon(Icons.chevron_left_rounded, color: scheme.onSurfaceVariant),
                rightChevronIcon: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: theme.textTheme.labelSmall!.copyWith(color: scheme.onSurfaceVariant),
                weekendStyle: theme.textTheme.labelSmall!.copyWith(color: scheme.onSurfaceVariant),
              ),
              daysOfWeekHeight: 22,
              calendarStyle: CalendarStyle(
                // Daire küçük kalsın: alttaki işaret noktaları seçili/bugün dairesine binmesin.
                cellMargin: const EdgeInsets.all(8),
                outsideTextStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.45)),
                weekendTextStyle: TextStyle(color: scheme.onSurface),
                defaultTextStyle: TextStyle(color: scheme.onSurface),
                todayDecoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.14), shape: BoxShape.circle),
                todayTextStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                selectedDecoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                selectedTextStyle: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700),
              ),
              calendarBuilders: CalendarBuilders<Task>(
                markerBuilder: (context, day, events) =>
                    events.isEmpty ? null : _DayMarkers(day: day, tasks: events, now: now),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Günün altındaki noktalar: kırmızı = gecikmiş, indigo = açık, yeşil = tamamlanmış.
class _DayMarkers extends StatelessWidget {
  const _DayMarkers({required this.day, required this.tasks, required this.now});

  final DateTime day;
  final List<Task> tasks;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = context.statusColors;
    final kinds = dayMarkers(tasks, now);
    final id = DateFormat('yyyy-MM-dd').format(day);
    return Positioned(
      bottom: 1,
      child: Row(
        key: Key('calendar.markers.$id'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, kind) in kinds.indexed)
            Container(
              key: Key('calendar.marker.$id.$i.${kind.name}'),
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: switch (kind) {
                  CalendarMarkerKind.overdue => status.overdue,
                  CalendarMarkerKind.open => scheme.primary,
                  CalendarMarkerKind.done => status.done.withValues(alpha: 0.6),
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Seçili günün görevleri + "Bu güne görev ekle".
class _DayTasksPanel extends ConsumerWidget {
  /// [embedded]: dar ekranda sayfanın kaydırılan listesinin parçası (kendisi kaydırmaz).
  const _DayTasksPanel({this.embedded = false});

  final bool embedded;

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error is ApiException ? error.message : 'İşlem başarısız oldu.')));
  }

  Future<void> _setStatus(BuildContext context, WidgetRef ref, Task task, TaskStatus status) async {
    try {
      await ref.read(calendarTasksProvider.notifier).setStatus(task, status);
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Task task) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(calendarTasksProvider.notifier).delete(task);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('"${task.title}" silindi')));
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final day = ref.watch(calendarSelectedDayProvider);
    final async = ref.watch(calendarTasksProvider);
    final tasks = ref.watch(calendarTasksByDayProvider)[calendarDay(day)] ?? const <Task>[];
    final tree = ref.watch(categoryTreeProvider).value;
    final now = DateTime.now();

    final List<Widget> items;
    if (async.hasError && !async.hasValue) {
      items = [
        _PanelMessage(
          icon: Icons.cloud_off_outlined,
          text: async.error is ApiException ? (async.error! as ApiException).message : 'Görevler yüklenemedi.',
          action: TextButton(onPressed: () => ref.invalidate(calendarTasksProvider), child: const Text('Tekrar dene')),
        ),
      ];
    } else if (tasks.isEmpty) {
      items = [
        _PanelMessage(
          icon: Icons.event_available_outlined,
          text: async.isLoading && !async.hasValue ? 'Yükleniyor…' : 'Bu gün için görev yok.',
        ),
      ];
    } else {
      items = [
        for (final (i, task) in tasks.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          TaskCard(
            key: ValueKey('calendar-${task.id}'),
            task: task,
            now: now,
            category: tree?[task.categoryId],
            onToggleDone: () => _setStatus(context, ref, task, task.isDone ? TaskStatus.todo : TaskStatus.done),
            onStatusChanged: (s) => _setStatus(context, ref, task, s),
            onEdit: () => showTaskForm(context, task: task),
            onDelete: () => _delete(context, ref, task),
          ),
        ],
      ];
    }
    final list = embedded
        ? Column(key: const Key('calendar.dayTasks'), crossAxisAlignment: CrossAxisAlignment.stretch, children: items)
        : ListView(key: const Key('calendar.dayTasks'), padding: const EdgeInsets.only(bottom: 24), children: items);

    return Column(
      mainAxisSize: embedded ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('d MMMM, EEEE', 'tr_TR').format(day),
                    key: const Key('calendar.dayTitle'),
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    tasks.isEmpty
                        ? relativeDayLabel(day, now: now)
                        : '${relativeDayLabel(day, now: now)} · ${tasks.length} görev',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              key: const Key('calendar.addForDay'),
              onPressed: () => showTaskForm(context, defaultDueDate: endOfDay(day)),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Bu güne görev ekle'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (embedded) list else Expanded(child: list),
      ],
    );
  }
}

class _PanelMessage extends StatelessWidget {
  const _PanelMessage({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: context.surfaces.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: scheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
