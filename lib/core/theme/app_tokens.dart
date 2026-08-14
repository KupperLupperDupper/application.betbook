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
  // v5 full-bleed: the active card runs edge-to-edge. The peek is gone; the
  // swipe cue is the nav pill + first-run nudge + an 8 dp drag-only seam.
  static const viewportFraction = 1.0; // was 0.92 \u2014 device-confirmable knob
  static const dragSeam = 8.0; // page surface shown between cards while dragging
  static const cardPadding = EdgeInsets.zero;
  static const shape = BorderRadius.vertical(top: Radius.circular(28));
  static const sectionPadding =
      EdgeInsets.only(left: 20, right: 20, bottom: 140);
  static const flingThreshold = 350.0; // px/s
  static const spring = SpringDescription(mass: 1, stiffness: 220, damping: 26);
  static const suits = ['\u2660', '\u2665', '\u2666', '\u2663'];
}

/// Bottom bar (v6): one anchored `♠ ♥ (+) ♦ ♣` pill carrying the section
/// indicators and the centred add action. Contracts 304 → 232 dp when the add
/// button drops out on sections with no add action. See BOTTOMBAR_HANDOFF.md.
class AppBottomBar {
  static const double height = 64;
  static const double widthExpanded = 304; // with the add button
  static const double widthCollapsed = 232; // without it
  static const double radius = 32;
  static const double padding = 6;
  static const double bottomInset = 20; // max(this, viewPadding.bottom)
  static const double itemSize = 48; // per suit, visual box = tap target
  static const double itemGap = 4; // within a pair
  static const double centreGap = 20; // each side of the button
  static const double centreGapTight = 10; // between the pairs, button away
  static const double slot = 52; // centre slot width with the button (0 without)
  static const double glyphResting = 15;
  static const double glyphActive = 17;
  static const double underlineW = 10;
  static const double underlineH = 3;
  static const double underlineGap = 5;
  static const double addSize = 52; // circular, radius = addSize / 2
  static const double addGlyph = 26;

  // Motion: one controller drives the button opacity/drop, the centre gap and
  // the bar width together.
  static const Duration addOut = Duration(milliseconds: 200);
  static const Duration addIn = Duration(milliseconds: 220);
  static const Curve addCurve = Curves.easeOutCubic;
  static const double addHiddenDy = 40; // dp, straight down, no scale
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
