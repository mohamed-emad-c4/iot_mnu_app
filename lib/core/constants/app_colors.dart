import 'package:flutter/material.dart';

/// Central color palette for the Smart Irrigation app.
///
/// Uses a green-primary scheme that evokes agriculture and nature.
/// All colours are defined for both light and dark variants so that
/// nothing is hard-coded in widgets.
abstract final class AppColors {
  // ─── Brand greens ────────────────────────────────────────────────────────
  static const green50 = Color(0xFFE8F5E9);
  static const green100 = Color(0xFFC8E6C9);
  static const green200 = Color(0xFFA5D6A7);
  static const green400 = Color(0xFF66BB6A);
  static const green500 = Color(0xFF4CAF50); // primary
  static const green600 = Color(0xFF43A047);
  static const green700 = Color(0xFF388E3C);
  static const green800 = Color(0xFF2E7D32);
  static const green900 = Color(0xFF1B5E20);

  // ─── Moisture-status colours ─────────────────────────────────────────────
  static const dry = Color(0xFFEF5350); // red-ish
  static const dryLight = Color(0xFFFFEBEE);
  static const ok = Color(0xFF4CAF50); // green
  static const okLight = Color(0xFFE8F5E9);
  static const wet = Color(0xFF29B6F6); // blue
  static const wetLight = Color(0xFFE1F5FE);

  // ─── Neutrals ────────────────────────────────────────────────────────────
  static const surfaceDark = Color(0xFF121212);
  static const surfaceDark2 = Color(0xFF1E1E1E);
  static const surfaceDark3 = Color(0xFF2C2C2C);
  static const cardDark = Color(0xFF1F2A1F); // very dark green tint
  static const cardDark2 = Color(0xFF1A2B1A);

  // ─── Status ──────────────────────────────────────────────────────────────
  static const warning = Color(0xFFFFA726);
  static const warningLight = Color(0xFFFFF3E0);
  static const error = Color(0xFFEF5350);
  static const info = Color(0xFF29B6F6);
}
