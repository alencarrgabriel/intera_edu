import 'package:flutter/material.dart';

/// Design tokens do sistema Stitch — InteraEdu.
/// Todos os valores de cor derivam deste arquivo.
abstract final class AppTokens {
  // ── Primary ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF4355B9);
  static const Color primaryDim = Color(0xFF3649AC);
  static const Color primaryContainer = Color(0xFFDEE0FF);
  static const Color onPrimary = Color(0xFFF9F6FF);
  static const Color onPrimaryContainer = Color(0xFF3648AC);

  // ── Background / Surface ───────────────────────────────────────────────────
  static const Color background = Color(0xFFFBF8FC);
  static const Color surface = Color(0xFFFBF8FC);
  static const Color surfaceDim = Color(0xFFDAD9E5);

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F2F8);
  static const Color surfaceContainer = Color(0xFFEFEDF4);
  static const Color surfaceContainerHigh = Color(0xFFE9E7F0);
  static const Color surfaceContainerHighest = Color(0xFFE3E1EC);

  // ── On-surface ─────────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFF31323A);
  static const Color onSurfaceVariant = Color(0xFF5E5E67);

  // ── Outline ────────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF7A7A83);
  static const Color outlineVariant = Color(0xFFB2B1BB);

  // ── Secondary ──────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF5E5E67);
  static const Color secondaryContainer = Color(0xFFE3E1EC);
  static const Color secondaryDim = Color(0xFF52525B);

  // ── Tertiary ───────────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF535F78);
  static const Color tertiaryContainer = Color(0xFFD1DDFA);

  // ── Error ──────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFF9E3F4E);
  static const Color errorContainer = Color(0xFFFF8B9A);
  static const Color onError = Color(0xFFFFFFFF);

  // ── Gradient ───────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDim],
  );

  // ── Shadow ─────────────────────────────────────────────────────────────────
  /// Ambient shadow Stitch: on-surface 4 % opacidade, 24px blur, 8px Y
  static List<BoxShadow> get ambientShadow => [
    BoxShadow(
      color: onSurface.withValues(alpha: 0.04),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.20),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ── Blur / Glass ───────────────────────────────────────────────────────────
  static const double glassBlur = 20.0;
  static const Color glassColor = Color(0xCCFFFFFF); // white 80 %

  // ── Radii ──────────────────────────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 999.0;
}
