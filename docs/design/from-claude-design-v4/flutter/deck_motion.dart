import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// Motion + card-personality constants. See MOTION_HANDOFF.md.
///
/// v3 (amplitude tuning): swipe falloff, tilt, stack drop, deal-in geometry and
/// the count-up wave were all raised because v2 was imperceptible on device.
/// Curves, spring and haptics are unchanged — this is amplitude, not character.
///
/// Use `Motion.of(context)` so reduced-motion is handled once: every duration
/// it hands back is Duration.zero when the user disabled animations, which
/// makes most implicit animations resolve instantly with no branching.
class Motion {
  const Motion._(this.reduced);

  factory Motion.of(BuildContext context) =>
      Motion._(MediaQuery.disableAnimationsOf(context));

  final bool reduced;

  Duration _d(int ms) => reduced ? Duration.zero : Duration(milliseconds: ms);

  /// Interpolate only when motion is allowed; otherwise jump to `to`.
  double t(double from, double to, double t) =>
      reduced ? to : lerpDouble(from, to, t)!;

  // ── Deck ──────────────────────────────────────────────────────────────
  Duration get deckPageJump => _d(380); // adjacent card, indicator tap
  Duration get deckPageJumpFar => _d(440); // 2–3 card jump
  Duration get dealInCard => _d(460);
  Duration get dealInStagger => _d(110);
  Duration get dealInIndicator => _d(200);
  Duration get dealInFab => _d(180);
  Duration get dealInCancel => _d(120);

  // Settle emphasis — hairline brightens and returns (§1.5). Never fires when
  // reduced: the haptic carries the settle on its own.
  Duration get settleIn => _d(140);
  Duration get settleHold => _d(60);
  Duration get settleOut => _d(220);
  bool get settleEmphasis => !reduced;

  // ── Refresh shuffle ───────────────────────────────────────────────────
  Duration get riffleSuit => _d(180);
  Duration get riffleStep => _d(90);
  Duration get rifflePause => _d(120);
  Duration get refreshMinVisible => const Duration(milliseconds: 700); // real, not motion
  Duration get refreshCollapse => _d(200);

  // ── Loader + skeletons ────────────────────────────────────────────────
  Duration get loaderCycle => _d(880);
  Duration get loaderStagger => _d(110);
  Duration get shimmerSweep => _d(1200);
  Duration get shimmerPause => _d(400);
  Duration get skeletonMinVisible => const Duration(milliseconds: 400);
  Duration get skeletonCrossFade => _d(150);

  // ── Money ─────────────────────────────────────────────────────────────
  Duration get countUp => _d(400); // hero figure
  Duration get countUpSecondary => _d(280); // every other money figure
  Duration get countUpStagger => _d(90); // Dashboard / site detail
  Duration get countUpStaggerRow => _d(60); // Sites list rows
  Duration get zeroCrossing => _d(250);

  /// Hard cap on simultaneously animating figures; the rest render final.
  static const int countUpMaxFigures = 6;

  /// Delay for the [i]-th figure in the wave (0 = hero, animates immediately).
  Duration countUpDelay(int i, {bool listRow = false}) =>
      i >= countUpMaxFigures
          ? Duration.zero
          : (listRow ? countUpStaggerRow : countUpStagger) * i;

  /// Secondary figures never animate colour — only the hero may cross zero.
  Duration countUpFor(int i) => i == 0 ? countUp : countUpSecondary;

  // ── Misc ──────────────────────────────────────────────────────────────
  Duration get heroChipIn => _d(220);
  Duration get pressState => _d(80);

  static const Curve entrance = Curves.easeOutCubic;
  static const Curve settleRelease = Curves.easeOutSine;
  static const Curve loop = Curves.easeInOutSine;
  static const Curve sweep = Curves.linear;

  /// One soft settle, no wobble. Drags only — programmatic jumps use easeOutCubic.
  static const SpringDescription deckSpring =
      SpringDescription(mass: 1, stiffness: 220, damping: 26);

  static const double deckFlingThreshold = 350; // px/s

  /// Fires on deck settle and on refresh-armed. Nowhere else.
  static void tick() => HapticFeedback.selectionClick();
}

/// Per-card deal-in geometry (§1.3). Cards enter back-to-front: ♣ ♦ ♥ ♠.
class DealIn {
  static const Offset fromOffset = Offset(44, 26); // dp
  static const double fromScale = 0.94;
  static const double fromRotation = 0.0785; // rad ≈ +4.5°
  static const List<int> order = [3, 2, 1, 0]; // deck index order of entry

  /// Delay for the card at [deckIndex] (0 = Dashboard ♠, lands last).
  static Duration delayFor(int deckIndex, Motion m) =>
      m.dealInStagger * (3 - deckIndex);
}

/// Deck transition interpolation against PageView offset (§1.1).
class DeckTransform {
  /// Hard ceiling — 2.4° is the working value, past 3° it reads as a card table.
  static const double tiltCeiling = 0.0524; // rad = 3.0°

  /// [offset] = (page - index).abs(), clamped 0..1.
  static double scale(double offset) => 1.0 - 0.10 * offset;
  static double opacity(double offset) => 1.0 - 0.26 * offset;
  static double hairlineOpacity(double offset) => 1.0 - 0.70 * offset;

  /// Neighbours sit lower in the stack — the cheapest depth cue we have.
  static double stackDrop(double offset) => 6.0 * offset; // dp

  /// Signed tilt in radians; [delta] = page - index (keeps direction).
  static double tilt(double delta) =>
      (-0.0419 * delta.clamp(-1.0, 1.0)).clamp(-tiltCeiling, tiltCeiling);

  /// Content parallax translation in px; [delta] = page - index.
  static double parallax(double delta, double width) => -0.22 * delta * width;

  /// Everything pinned to the active card's values when motion is disabled.
  static double scaleFor(double offset, Motion m) => m.reduced ? 1.0 : scale(offset);
  static double opacityFor(double offset, Motion m) => m.reduced ? 1.0 : opacity(offset);
  static double dropFor(double offset, Motion m) => m.reduced ? 0.0 : stackDrop(offset);
  static double tiltFor(double delta, Motion m) => m.reduced ? 0.0 : tilt(delta);
  static double parallaxFor(double delta, double w, Motion m) =>
      m.reduced ? 0.0 : parallax(delta, w);
  static double hairlineFor(double offset, Motion m) =>
      m.reduced ? 1.0 : hairlineOpacity(offset);
}

/// Mini playing-card avatar geometry (§3.1). Aspect is fixed at 1 : 1.375.
enum CardChipSize { dense, row, hero }

class CardChip {
  static const Map<CardChipSize, double> width = {
    CardChipSize.dense: 24,
    CardChipSize.row: 32,
    CardChipSize.hero: 64,
  };
  static const Map<CardChipSize, double> height = {
    CardChipSize.dense: 33,
    CardChipSize.row: 44,
    CardChipSize.hero: 88,
  };
  static const Map<CardChipSize, double> radius = {
    CardChipSize.dense: 5,
    CardChipSize.row: 6,
    CardChipSize.hero: 10,
  };
  static const Map<CardChipSize, double> rankSize = {
    CardChipSize.dense: 13,
    CardChipSize.row: 17,
    CardChipSize.hero: 34,
  };
  /// Null = pip omitted (too small to stay legible).
  static const Map<CardChipSize, double?> pipSize = {
    CardChipSize.dense: null,
    CardChipSize.row: 8,
    CardChipSize.hero: 14,
  };
  static const Map<CardChipSize, double> pipInset = {
    CardChipSize.dense: 0,
    CardChipSize.row: 3,
    CardChipSize.hero: 6,
  };

  /// Rank + pip ink. Both branches clear 4.5:1 on every palette hue.
  static Color inkOn(Color fill) => fill.computeLuminance() < 0.45
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF1A1B20);

  /// Light theme only — keeps a pale fill reading as an object on white.
  static const Color hairlineLight = Color(0x1F000000); // #000 @ 12%
}

/// Suit texture, deterministic and stable across processes and platforms.
class SiteSuit {
  static const List<String> glyphs = ['♠', '♥', '♦', '♣'];

  /// Dart's hashCode is not stable across runs — hash the id ourselves.
  static int fnv1a32(String s) {
    var hash = 0x811c9dc5;
    for (final unit in s.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  /// Pass the immutable site id — never the name (renaming must not reshuffle).
  static String forSiteId(String siteId) => glyphs[fnv1a32(siteId) % 4];
}

/// Deck card edge treatment (§6). No paper texture — hairlines only.
class DeckSurface {
  static const Color hairlineLight = Color(0x8CC4C6D0); // outlineVariant @ 55%
  static const Color hairlineDark = Color(0x12FFFFFF); // white @ 7%
  static const Color hairlineSettleLight = Color(0xB374777F); // outline @ 70%
  static const Color hairlineSettleDark = Color(0x2EFFFFFF); // white @ 18%
  static const Color topHighlightDark = Color(0x0AFFFFFF); // white @ 4%
  static const Color pipLight = Color(0xB374777F); // outline @ 70%
  static const Color pipDark = Color(0xB38E9099);

  static Color hairline(Brightness b) =>
      b == Brightness.dark ? hairlineDark : hairlineLight;

  /// Peak of the 420 ms settle emphasis (§1.5) — stroke only, never the fill.
  static Color hairlineSettle(Brightness b) =>
      b == Brightness.dark ? hairlineSettleDark : hairlineSettleLight;
  static Color pip(Brightness b) => b == Brightness.dark ? pipDark : pipLight;
}

/// Skeleton shimmer tokens (§4.2).
class SkeletonTokens {
  static const double bandFraction = 0.40;
  static Color highlight(Brightness b) => b == Brightness.dark
      ? const Color(0x0FFFFFFF) // white @ 6%
      : const Color(0x0A1A1B20); // onSurface @ 4%
  static const double radiusLine = 8;
  static const double radiusChip = 12;
  static const double radiusCard = 16;
}
