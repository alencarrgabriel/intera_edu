import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/app_tokens.dart';
import '../design/app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final cs = _colorScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: AppTypography.textTheme,
      scaffoldBackgroundColor: AppTokens.background,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTokens.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTypography.textTheme.titleLarge,
      ),

      // ── Cards ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppTokens.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Inputs ──────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide(
            color: AppTokens.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide(
            color: AppTokens.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(
            color: AppTokens.primaryContainer,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle:
            const TextStyle(color: AppTokens.onSurfaceVariant, fontSize: 14),
        hintStyle: TextStyle(
            color: AppTokens.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 14),
      ),

      // ── FilledButton ────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppTokens.primary,
          foregroundColor: AppTokens.onPrimary,
          disabledBackgroundColor:
              AppTokens.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor:
              AppTokens.onSurface.withValues(alpha: 0.38),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ── ElevatedButton ──────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.primary,
          foregroundColor: AppTokens.onPrimary,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── TextButton ──────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTokens.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── OutlinedButton ──────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.primary,
          side: const BorderSide(color: AppTokens.primaryContainer, width: 1.5),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
      ),

      // ── BottomNav ───────────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppTokens.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppTokens.onPrimaryContainer);
          }
          return const IconThemeData(color: AppTokens.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTokens.primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppTokens.onSurfaceVariant,
          );
        }),
      ),

      // ── Chips ───────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppTokens.surfaceContainerLow,
        selectedColor: AppTokens.primaryContainer,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          side: BorderSide.none,
        ),
      ),

      // ── SnackBar ────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppTokens.onSurface,
        contentTextStyle:
            TextStyle(color: AppTokens.surface, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),

      // ── Floating Action Button ───────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppTokens.primary,
        foregroundColor: AppTokens.onPrimary,
        elevation: 0,
        shape: StadiumBorder(),
      ),
    );
  }

  static ColorScheme get _colorScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: AppTokens.primary,
    onPrimary: AppTokens.onPrimary,
    primaryContainer: AppTokens.primaryContainer,
    onPrimaryContainer: AppTokens.onPrimaryContainer,
    secondary: AppTokens.secondary,
    onSecondary: AppTokens.surfaceContainerLowest,
    secondaryContainer: AppTokens.secondaryContainer,
    onSecondaryContainer: AppTokens.onSurface,
    tertiary: AppTokens.tertiary,
    onTertiary: AppTokens.surfaceContainerLowest,
    tertiaryContainer: AppTokens.tertiaryContainer,
    onTertiaryContainer: AppTokens.onSurface,
    error: AppTokens.error,
    onError: AppTokens.onError,
    errorContainer: AppTokens.errorContainer,
    onErrorContainer: AppTokens.onSurface,
    surface: AppTokens.surface,
    onSurface: AppTokens.onSurface,
    surfaceContainerLowest: AppTokens.surfaceContainerLowest,
    surfaceContainerLow: AppTokens.surfaceContainerLow,
    surfaceContainer: AppTokens.surfaceContainer,
    surfaceContainerHigh: AppTokens.surfaceContainerHigh,
    surfaceContainerHighest: AppTokens.surfaceContainerHighest,
    onSurfaceVariant: AppTokens.onSurfaceVariant,
    outline: AppTokens.outline,
    outlineVariant: AppTokens.outlineVariant,
    inverseSurface: AppTokens.onSurface,
    onInverseSurface: AppTokens.surface,
    inversePrimary: AppTokens.primaryContainer,
  );

  // Utilitário: constrói um AppBar glassmórfico para uso em telas individuais.
  static PreferredSizeWidget glassAppBar({
    required BuildContext context,
    Widget? title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    PreferredSizeWidget? bottom,
  }) {
    return PreferredSize(
      preferredSize: Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0)),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTokens.glassBlur,
            sigmaY: AppTokens.glassBlur,
          ),
          child: AppBar(
            backgroundColor: AppTokens.glassColor,
            foregroundColor: AppTokens.onSurface,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: title,
            actions: actions,
            leading: leading,
            automaticallyImplyLeading: automaticallyImplyLeading,
            bottom: bottom,
          ),
        ),
      ),
    );
  }

  // Não há darkTheme diferenciado nesta fase — placeholder.
  static ThemeData get darkTheme => lightTheme;
}
