import 'package:flutter/material.dart';

/// "Clarity Workspace" tasarım sisteminin renk paleti.
///
/// Anahtar renkler:
///  - Primary   #4F46E5 (indigo)   — koyu temada #6366F1 tonu
///  - Secondary #64748B (slate)
///  - Tertiary  #10B981 (emerald) — koyu temada ikincil vurgu, amber (#F59E0B) üçüncül
///  - Neutral   #0F172A (gece mavisi)
abstract final class AppColors {
  // ── Anahtar renkler ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF64748B);
  static const Color tertiary = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color neutral = Color(0xFF0F172A);

  // ── Indigo tonları (primary) ─────────────────────────────────────────────
  static const Color indigo50 = Color(0xFFEEF2FF);
  static const Color indigo100 = Color(0xFFE0E7FF);
  static const Color indigo200 = Color(0xFFC7D2FE);
  static const Color indigo300 = Color(0xFFA5B4FC);
  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo800 = Color(0xFF3730A3);
  static const Color indigo900 = Color(0xFF312E81);
  static const Color indigo950 = Color(0xFF1E1B4B);

  // ── Slate tonları (secondary / neutral) ──────────────────────────────────
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);

  // ── Emerald tonları (tertiary) ───────────────────────────────────────────
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald900 = Color(0xFF064E3B);
  static const Color emerald950 = Color(0xFF022C22);

  // ── Amber tonları (koyu tema üçüncül) ────────────────────────────────────
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber900 = Color(0xFF78350F);
  static const Color amber950 = Color(0xFF451A03);

  // ── Açık tema yüzeyleri (indigo'ya çok hafif kaymış nötrler) ─────────────
  static const Color lightBackground = Color(0xFFF5F6FB);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightContainerLow = Color(0xFFF0F2F8);
  static const Color lightContainer = Color(0xFFEAEDF5);
  static const Color lightContainerHigh = Color(0xFFE3E7F0);
  static const Color lightContainerHighest = Color(0xFFDBE0EB);
  static const Color lightBorder = Color(0xFFE6E9F2);

  // ── Koyu tema yüzeyleri (Neutral #0F172A tabanlı) ────────────────────────
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSidebar = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF141D31);
  static const Color darkContainerLowest = Color(0xFF080D19);
  static const Color darkContainerLow = Color(0xFF111A2D);
  static const Color darkContainer = Color(0xFF172036);
  static const Color darkContainerHigh = Color(0xFF1E293B);
  static const Color darkContainerHighest = Color(0xFF273449);
  static const Color darkBorder = Color(0xFF222D44);
}
