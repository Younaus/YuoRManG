import 'package:flutter/material.dart';

/// Kategori renk paleti (backend'e '#RRGGBB' olarak gider).
const categoryPalette = <String>[
  '#4F46E5', // indigo
  '#0EA5E9', // sky
  '#10B981', // emerald
  '#F59E0B', // amber
  '#F43F5E', // rose
  '#8B5CF6', // violet
  '#F97316', // orange
  '#64748B', // slate
];

Color? colorFromHex(String? hex) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
  final value = int.tryParse(hex.substring(1), radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}

/// Kategori rengini gösteren küçük nokta; renk yoksa nötr ton.
class CategoryDot extends StatelessWidget {
  const CategoryDot({required this.hex, this.size = 10, super.key});

  final String? hex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(hex) ?? Theme.of(context).colorScheme.outline;
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}
