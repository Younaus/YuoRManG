import 'package:flutter/material.dart';

/// Boş liste / yer tutucu ekranlar için ortak görünüm.
class EmptyState extends StatelessWidget {
  const EmptyState({required this.icon, required this.title, this.message, this.action, super.key});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: scheme.surfaceContainerHigh, shape: BoxShape.circle),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Icon(icon, size: 32, color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}
