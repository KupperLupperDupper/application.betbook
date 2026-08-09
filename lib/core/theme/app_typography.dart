import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Manrope, fallback Roboto -> platform sans. JetBrains Mono for chart axes.
class AppTypography {
  static const _tabular = [FontFeature.tabularFigures()];

  static TextTheme textTheme(Color onSurface) {
    final base = GoogleFonts.manropeTextTheme().apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );
    return base.copyWith(
      displayLarge: base.displayLarge!.copyWith(fontSize: 57, height: 64 / 57, fontWeight: FontWeight.w800, letterSpacing: -0.25),
      displayMedium: base.displayMedium!.copyWith(fontSize: 45, height: 52 / 45, fontWeight: FontWeight.w700),
      displaySmall: base.displaySmall!.copyWith(fontSize: 36, height: 44 / 36, fontWeight: FontWeight.w700),
      headlineLarge: base.headlineLarge!.copyWith(fontSize: 32, height: 40 / 32, fontWeight: FontWeight.w700),
      headlineMedium: base.headlineMedium!.copyWith(fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w700),
      headlineSmall: base.headlineSmall!.copyWith(fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge!.copyWith(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w700),
      titleMedium: base.titleMedium!.copyWith(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w600, letterSpacing: 0.15),
      titleSmall: base.titleSmall!.copyWith(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      bodyLarge: base.bodyLarge!.copyWith(fontSize: 16, height: 24 / 16, letterSpacing: 0.5),
      bodyMedium: base.bodyMedium!.copyWith(fontSize: 14, height: 20 / 14, letterSpacing: 0.25),
      bodySmall: base.bodySmall!.copyWith(fontSize: 12, height: 16 / 12, letterSpacing: 0.4),
      labelLarge: base.labelLarge!.copyWith(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: base.labelMedium!.copyWith(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      labelSmall: base.labelSmall!.copyWith(fontSize: 11, height: 16 / 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    );
  }

  // --- money styles: always tabular so totals never jitter ---

  /// type.display.pl — the hero P/L figure.
  static TextStyle displayPL(Color c) => GoogleFonts.manrope(
        color: c, fontSize: 57, height: 60 / 57,
        fontWeight: FontWeight.w800, letterSpacing: -1.0, fontFeatures: _tabular,
      );

  /// type.total.secondary — deposited / withdrawn totals.
  static TextStyle totalSecondary(Color c) => GoogleFonts.manrope(
        color: c, fontSize: 22, height: 28 / 22,
        fontWeight: FontWeight.w700, fontFeatures: _tabular,
      );

  /// type.row.amount — list-row amounts.
  static TextStyle rowAmount(Color c) => GoogleFonts.manrope(
        color: c, fontSize: 16, height: 24 / 16,
        fontWeight: FontWeight.w700, letterSpacing: 0.15, fontFeatures: _tabular,
      );

  /// type.chart.axis — chart axis labels.
  static TextStyle chartAxis(Color c) => GoogleFonts.jetBrainsMono(
        color: c, fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w500,
      );
}
