import 'package:flutter/material.dart';

class AppSpace {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s12 = 48.0;

  /// 16 dp, 24 dp on phones >= 400 dp wide.
  static double screenX(BuildContext c) =>
      MediaQuery.sizeOf(c).width >= 400 ? 24 : 16;

  static const listRowMinHeight = 64.0;
  static const minTapTarget = 48.0;
}

class AppRadius {
  static const deck = 28.0;
  static const card = 16.0;
  static const sheet = 28.0;
  static const button = 20.0;
  static const fab = 16.0;
  static const field = 12.0;
  static const avatar = 10.0;
  static const chip = 999.0;
}

/// Tonal elevation, not shadows. The FAB is the only shadowed surface,
/// and only in the light theme.
class AppElevation {
  static const fabShadowLight = BoxShadow(
    color: Color(0x2E000000), blurRadius: 4, offset: Offset(0, 2),
  );
  static const scrimLight = Color(0x52000000); // 32%
  static const scrimDark = Color(0x80000000);  // 50%
}

/// Deck navigation constants — see DESIGN_HANDOFF.md section 6.
class AppDeck {
  static const viewportFraction = 0.92;
  static const neighbourScale = 0.94;
  static const neighbourOpacity = 0.86;
  static const parallaxFactor = 0.15;
  static const peekWidth = 14.0;      // 18 at >= 400 dp
  static const flingThreshold = 350.0; // px/s
  static const spring = SpringDescription(mass: 1, stiffness: 220, damping: 26);
  static const suits = ['\u2660', '\u2665', '\u2666', '\u2663'];
}

/// Categorical series palette. Pair each hue with a distinct marker shape.
class ChartPalette {
  static const light = [
    Color(0xFF3B5F9E), Color(0xFF2E7D8F), Color(0xFF0F6E52), Color(0xFF4C6B2F),
    Color(0xFF8A6D1F), Color(0xFFB3401A), Color(0xFF9A3B63), Color(0xFF6F5675),
  ];
  static const dark = [
    Color(0xFFA8C4FF), Color(0xFF7FCBDC), Color(0xFF6FD9B3), Color(0xFFA6CE7E),
    Color(0xFFDFC169), Color(0xFFFFB59A), Color(0xFFF3A0C0), Color(0xFFDDBCE0),
  ];
}
