import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/deck_motion.dart';
import '../features/home/playing_card.dart';
import 'suit_icon.dart';

/// A site avatar shaped like a small playing card (MOTION_HANDOFF §3):
/// the site's colour as the fill, the name's initial as the "rank", and a
/// deterministic suit pip in the corner. Decorative — excluded from semantics.
class MiniCardAvatar extends StatelessWidget {
  const MiniCardAvatar({
    super.key,
    required this.siteId,
    required this.name,
    required this.colorValue,
    this.size = CardChipSize.row,
  });

  final String siteId;
  final String name;
  final int colorValue;
  final CardChipSize size;

  @override
  Widget build(BuildContext context) {
    final fill = Color(colorValue);
    final ink = CardChip.inkOn(fill);
    final w = CardChip.width[size]!;
    final h = CardChip.height[size]!;
    final r = CardChip.radius[size]!;
    final rankSize = CardChip.rankSize[size]!;
    final pip = CardChip.pipSize[size];
    final pipInset = CardChip.pipInset[size]!;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final suit = CardSuit.values[SiteSuit.fnv1a32(siteId) % 4];
    final initial =
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return ExcludeSemantics(
      child: SizedBox(
        width: w,
        height: h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(r),
            // Inner hairline keeps a pale fill reading as an object on white.
            border: isLight
                ? Border.all(color: CardChip.hairlineLight, width: 1)
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.12),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w700,
                        fontSize: rankSize,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              if (pip != null) ...[
                Positioned(
                  top: pipInset,
                  right: pipInset,
                  child: SuitIcon(suit: suit, color: ink, size: pip),
                ),
                if (size == CardChipSize.hero)
                  Positioned(
                    bottom: pipInset,
                    left: pipInset,
                    child: Transform.rotate(
                      angle: math.pi,
                      child: SuitIcon(suit: suit, color: ink, size: pip),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
