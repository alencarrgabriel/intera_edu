import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_tokens.dart';

/// Tipografia Stitch: Manrope para headlines, Inter para body/label.
abstract final class AppTypography {
  static TextTheme get textTheme {
    return TextTheme(
      // ── Display ─────────────────────────────────────────────────────────────
      displayLarge: GoogleFonts.manrope(
        fontSize: 57, fontWeight: FontWeight.w400, color: AppTokens.onSurface),
      displayMedium: GoogleFonts.manrope(
        fontSize: 45, fontWeight: FontWeight.w400, color: AppTokens.onSurface),
      displaySmall: GoogleFonts.manrope(
        fontSize: 36, fontWeight: FontWeight.w400, color: AppTokens.onSurface),

      // ── Headline ─────────────────────────────────────────────────────────────
      headlineLarge: GoogleFonts.manrope(
        fontSize: 32, fontWeight: FontWeight.w700, color: AppTokens.onSurface),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 28, fontWeight: FontWeight.w700, color: AppTokens.onSurface),
      headlineSmall: GoogleFonts.manrope(
        fontSize: 24, fontWeight: FontWeight.w600, color: AppTokens.onSurface),

      // ── Title ────────────────────────────────────────────────────────────────
      titleLarge: GoogleFonts.manrope(
        fontSize: 22, fontWeight: FontWeight.w700, color: AppTokens.onSurface),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppTokens.onSurface),
      titleSmall: GoogleFonts.manrope(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppTokens.onSurface),

      // ── Body ─────────────────────────────────────────────────────────────────
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: AppTokens.onSurface),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppTokens.onSurface),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: AppTokens.onSurfaceVariant),

      // ── Label ─────────────────────────────────────────────────────────────────
      labelLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppTokens.onSurface),
      labelMedium: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500, color: AppTokens.onSurfaceVariant),
      labelSmall: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w500, color: AppTokens.onSurfaceVariant),
    );
  }
}
