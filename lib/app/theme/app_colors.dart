import 'package:flutter/material.dart';

/// Brand palette. Single source of truth for seed + semantic colors.
abstract final class AppColors {
  /// Seed color for the Material 3 scheme (growth green).
  static const Color seed = Color(0xFF00A868);

  /// Positive movements (gains).
  static const Color positive = Color(0xFF1B873F);

  /// Negative movements (losses).
  static const Color negative = Color(0xFFD32F2F);

  /// Muted text / neutral state.
  static const Color neutral = Color(0xFF6B7280);
}
