import 'package:flutter/material.dart';
import '../design/app_tokens.dart';

/// Aliases de conveniência que mantêm compatibilidade com imports existentes.
/// Novos widgets devem usar [AppTokens] diretamente.
class AppColors {
  static const Color primary = AppTokens.primary;
  static const Color primaryLight = AppTokens.primaryContainer;
  static const Color primaryDark = AppTokens.primaryDim;

  static const Color background = AppTokens.background;
  static const Color surface = AppTokens.surfaceContainerLowest;
  static const Color textPrimary = AppTokens.onSurface;
  static const Color textSecondary = AppTokens.onSurfaceVariant;
  static const Color divider = AppTokens.outlineVariant;

  // dark mode (placeholder — app ainda usa apenas tema claro)
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);

  static const Color error = AppTokens.error;
}
