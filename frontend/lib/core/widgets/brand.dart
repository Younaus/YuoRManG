import 'package:flutter/material.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../theme/app_surfaces.dart';
import '../utils/text_case.dart';

/// Uygulama logosu: indigo zemin üzerinde onay işareti olan yuvarlatılmış kare.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({this.size = 36, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.surfaces.fab, Color.lerp(context.surfaces.fab, Colors.black, 0.18)!],
        ),
        boxShadow: [
          BoxShadow(color: scheme.primary.withValues(alpha: 0.30), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Icon(Icons.check_rounded, size: size * 0.62, color: context.surfaces.onFab),
    );
  }
}

/// Logo + iki satırlı başlık: küçük, büyük harfli üst satır ("YOURMANG") ve asıl başlık.
class AppTitleBlock extends StatelessWidget {
  const AppTitleBlock({required this.title, this.overline = 'YouRManG', this.showLogo = true, super.key});

  final String title;
  final String overline;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo) ...[const AppLogoMark(size: 34), const SizedBox(width: 12)],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                toUpperTr(overline),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(title, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// Baş harflerden oluşan, indigo tonlu kullanıcı avatarı.
class UserAvatar extends StatelessWidget {
  const UserAvatar({required this.user, this.radius = 18, super.key});

  final AppUser? user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primaryContainer,
        border: Border.all(color: context.surfaces.card, width: 2),
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.25), spreadRadius: 1.5)],
      ),
      child: Text(
        user?.initials ?? '?',
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.72,
        ),
      ),
    );
  }
}

/// Yuvarlak, indigo gölgeli belirgin FAB.
class AppFab extends StatelessWidget {
  const AppFab({required this.onPressed, required this.tooltip, this.icon = Icons.add_rounded, super.key});

  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final fab = context.surfaces.fab;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: fab.withValues(alpha: 0.30), blurRadius: 18, offset: const Offset(0, 8)),
          BoxShadow(color: fab.withValues(alpha: 0.20), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: FloatingActionButton(heroTag: null, tooltip: tooltip, onPressed: onPressed, child: Icon(icon)),
    );
  }
}

/// Bölüm başlığı: "BUGÜN 3" gibi küçük, aralıklı harfli etiket + isteğe bağlı aksiyon.
class SectionLabel extends StatelessWidget {
  const SectionLabel({required this.text, this.trailing, this.padding = EdgeInsets.zero, super.key});

  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              toUpperTr(text),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
