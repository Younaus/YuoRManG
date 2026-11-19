import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/desktop/corner_window_service.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/utils/text_case.dart';
import '../providers/corner_mode_providers.dart';
import '../providers/task_providers.dart';
import 'status_style.dart';

/// Uygulamanın kökünde: köşe modu açıkken asıl arayüzü (durumu korunarak, son tam pencere
/// boyutunda) gizler ve pencereyi dolduran [CornerFocusPill]'i gösterir.
class CornerModeHost extends ConsumerStatefulWidget {
  const CornerModeHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<CornerModeHost> createState() => _CornerModeHostState();
}

class _CornerModeHostState extends ConsumerState<CornerModeHost> {
  Size? _fullSize;

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(cornerModeProvider.select((s) => s.active));
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!active) _fullSize = constraints.biggest;
        // Köşe modunda arayüz son tam boyutunda tutulur: düzen telefona dönüşmez, taşma olmaz.
        final size = active ? (_fullSize ?? constraints.biggest) : constraints.biggest;
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            Offstage(
              offstage: active,
              child: TickerMode(
                enabled: !active,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(size: size),
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: size.width,
                    maxWidth: size.width,
                    minHeight: size.height,
                    maxHeight: size.height,
                    child: widget.child,
                  ),
                ),
              ),
            ),
            if (active) const Positioned.fill(child: CornerFocusPill()),
          ],
        );
      },
    );
  }
}

/// Ekran köşesindeki soft hap: nabız atan amber nokta, tek satır başlık,
/// sıradaki göreve geçiş, tek tıkla tamamlama ve tam pencereye dönüş.
class CornerFocusPill extends ConsumerStatefulWidget {
  const CornerFocusPill({super.key});

  @override
  ConsumerState<CornerFocusPill> createState() => _CornerFocusPillState();
}

class _CornerFocusPillState extends ConsumerState<CornerFocusPill> {
  bool _hovered = false;

  void _setHovered(bool hovered) {
    if (_hovered == hovered) return;
    setState(() => _hovered = hovered);
    ref.read(cornerWindowServiceProvider).setOpacity(hovered ? cornerHoverOpacity : cornerIdleOpacity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = context.surfaces;
    final status = context.statusColors;
    final mode = ref.watch(cornerModeProvider);
    final controller = ref.read(cornerModeProvider.notifier);
    final activeAsync = ref.watch(activeTasksProvider);
    final tasks = activeAsync.value ?? const [];
    final task = ref.watch(cornerFocusedTaskProvider);
    final completed = mode.completedTitle;
    final index = task == null ? -1 : tasks.indexWhere((t) => t.id == task.id);

    final (String overline, Color overlineColor) = switch (()) {
      _ when completed != null => ('Tamamlandı', status.done),
      _ when mode.error != null => ('${mode.error} · tekrar dene', scheme.error),
      _ when task == null && activeAsync.isLoading => ('Yükleniyor…', scheme.onSurfaceVariant),
      _ when task == null => ('Köşe modu', scheme.onSurfaceVariant),
      _ when tasks.length > 1 => ('Devam ediyor · ${index + 1}/${tasks.length}', status.inProgress),
      _ => ('Devam ediyor', status.inProgress),
    };
    final title = completed ?? task?.title ?? (activeAsync.isLoading ? '' : 'Devam eden görev yok');

    final Widget leading = completed != null
        ? Icon(Icons.check_circle_rounded, key: const Key('corner.completed'), size: 20, color: status.done)
        : task == null
        ? _Dot(color: scheme.outline)
        : _PulseDot(color: status.inProgress);

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Material(
        key: const Key('corner.pill'),
        color: surfaces.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: _hovered ? scheme.primary.withValues(alpha: 0.45) : surfaces.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ref
            .read(cornerWindowServiceProvider)
            .dragArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                child: Row(
                  children: [
                    SizedBox.square(dimension: 22, child: Center(child: leading)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            toUpperTr(overline),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                              color: overlineColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            key: const Key('corner.title'),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: completed != null ? scheme.onSurfaceVariant : scheme.onSurface,
                              decoration: completed != null ? TextDecoration.lineThrough : null,
                              decorationColor: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (completed == null && tasks.length > 1)
                      _PillIconButton(
                        key: const Key('corner.next'),
                        icon: Icons.chevron_right_rounded,
                        label: 'Sıradaki aktif görev',
                        onPressed: controller.focusNext,
                      ),
                    if (completed == null && task != null) _CompleteButton(onPressed: controller.completeFocused),
                    _PillIconButton(
                      key: const Key('corner.restore'),
                      icon: Icons.open_in_full_rounded,
                      iconSize: 16,
                      label: 'Tam pencereye dön',
                      onPressed: controller.exit,
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

/// Küçük, kompakt ikon butonu. Pencere 68 px yüksekliğinde olduğu için tooltip yerine
/// yalnızca erişilebilirlik etiketi kullanılır.
class _PillIconButton extends StatelessWidget {
  const _PillIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconSize = 20,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      icon: Icon(icon, size: iconSize, semanticLabel: label),
    );
  }
}

/// Tek tıkla "done": kartlardaki dairesel tamamlama butonunun küçük hâli; üzerine gelince dolar.
class _CompleteButton extends StatefulWidget {
  const _CompleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_CompleteButton> createState() => _CompleteButtonState();
}

class _CompleteButtonState extends State<_CompleteButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final done = context.statusColors.done;
    return Semantics(
      button: true,
      label: 'Tamamlandı olarak işaretle',
      child: InkResponse(
        key: const Key('corner.done'),
        onTap: widget.onPressed,
        onHover: (h) => setState(() => _hovered = h),
        radius: 18,
        child: SizedBox.square(
          dimension: 34,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hovered ? done : Colors.transparent,
                border: Border.all(color: done, width: 2),
              ),
              child: Icon(Icons.check_rounded, size: 15, color: _hovered ? context.surfaces.card : done),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Hafif nabız: sabit nokta + genişleyip kaybolan halka. "Animasyonları azalt" açıksa durağan.
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 10 + 10 * t,
              height: 10 + 10 * t,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.35 * (1 - t)),
              ),
            ),
            child!,
          ],
        );
      },
      child: _Dot(color: widget.color),
    );
  }
}

/// Masaüstü üst çubuğundaki "Köşe modu" düğmesi; yalnızca Windows'ta görünür.
class CornerModeButton extends ConsumerWidget {
  const CornerModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(cornerWindowServiceProvider).isSupported) return const SizedBox.shrink();
    final count = ref.watch(activeTasksProvider).value?.length ?? 0;
    return IconButton(
      key: const Key('tasks.cornerMode'),
      tooltip: count == 0 ? 'Köşe modu · devam eden görev yok' : 'Köşe modu · $count aktif görev',
      onPressed: count == 0 ? null : () => ref.read(cornerModeProvider.notifier).enter(),
      icon: Badge.count(
        count: count,
        isLabelVisible: count > 1,
        backgroundColor: context.statusColors.inProgress,
        child: const Icon(Icons.picture_in_picture_alt_outlined),
      ),
    );
  }
}
