import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/deck_motion.dart';
import '../../widgets/suit_icon.dart';

/// The four playing-card suits used as section identity/markers.
/// Deck order matches the design: Dashboard ♠ · Sites ♥ · Stats ♦ · Settings ♣.
/// Suits are drawn as vector paths (see [SuitIcon]) — never Unicode glyphs,
/// which many devices force to red emoji.
enum CardSuit { spade, heart, diamond, club }

/// A deck section presented as a printed playing card: full-bleed, hairline
/// edge, a quiet corner pip (the suit) and a small uppercase section label —
/// never a literal poker card. The card owns its section's scrolling content.
class PlayingCard extends StatelessWidget {
  const PlayingCard({
    super.key,
    required this.suit,
    required this.label,
    this.subtitle,
    required this.child,
    this.edgeLift = 1.0,
    this.settle = 0.0,
  });

  final CardSuit suit;
  final String label;
  final String? subtitle;
  final Widget child;

  /// 0.40 (neighbour) → 1.00 (active): the top card's hairline reads as
  /// physically on top of the stack (MOTION_HANDOFF §1.1 / §6).
  final double edgeLift;

  /// 0 → 1 → 0 pulse on the card that just landed (MOTION_HANDOFF §1.5): the
  /// hairline brightens toward [DeckSurface.hairlineSettle] and returns. Stroke
  /// only — never the fill. Stays 0 under reduced motion.
  final double settle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;

    final hairlineBase = DeckSurface.hairline(brightness);
    var hairline = hairlineBase.withValues(alpha: hairlineBase.a * edgeLift);
    if (settle > 0) {
      hairline =
          Color.lerp(hairline, DeckSurface.hairlineSettle(brightness), settle)!;
    }

    // v5 full-bleed: edge-to-edge, top-only radius, hairline flush to the
    // screen edge (bottom runs off-screen). The pip lives in the header band.
    return Padding(
      padding: AppDeck.cardPadding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: AppDeck.shape,
          border: Border.all(color: hairline),
        ),
        child: ClipRRect(
          borderRadius: AppDeck.shape,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header band (§3): section title + trailing suit pip.
                  SizedBox(
                    height: 52,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (subtitle != null)
                                  Text(
                                    subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SuitIcon(
                            suit: suit,
                            color: DeckSurface.pip(brightness),
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
              // Dark-only top-edge highlight, inset from the corners.
              if (brightness == Brightness.dark)
                Positioned(
                  top: 1,
                  left: 24,
                  right: 24,
                  child: Opacity(
                    opacity: edgeLift,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DeckSurface.topHighlightDark.withValues(alpha: 0),
                            DeckSurface.topHighlightDark,
                            DeckSurface.topHighlightDark.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
