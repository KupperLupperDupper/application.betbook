import 'package:flutter/material.dart';

import '../features/home/playing_card.dart';
import 'suit_icon.dart';

/// The app's brand mark: a 2×2 grid of suit glyphs in `onPrimary` on a
/// `primary` squircle. Used on onboarding and the lock screen.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: _SuitGrid(color: scheme.onPrimary, glyphSize: size * 0.26),
    );
  }
}

/// The empty-state mark: a 2×2 grid of suits in `onSurfaceVariant` on a
/// `surfaceContainerHighest` rounded square.
class SuitGlyphMark extends StatelessWidget {
  const SuitGlyphMark({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: _SuitGrid(color: scheme.onSurfaceVariant, glyphSize: size * 0.22),
    );
  }
}

class _SuitGrid extends StatelessWidget {
  const _SuitGrid({required this.color, required this.glyphSize});
  final Color color;
  final double glyphSize;

  @override
  Widget build(BuildContext context) {
    Widget cell(CardSuit s) =>
        Center(child: SuitIcon(suit: s, color: color, size: glyphSize));
    return Column(
      children: [
        Expanded(
          child: Row(children: [
            Expanded(child: cell(CardSuit.spade)),
            Expanded(child: cell(CardSuit.heart)),
          ]),
        ),
        Expanded(
          child: Row(children: [
            Expanded(child: cell(CardSuit.diamond)),
            Expanded(child: cell(CardSuit.club)),
          ]),
        ),
      ],
    );
  }
}
