import 'package:flutter/material.dart';

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
  });

  final CardSuit suit;
  final String label;
  final String? subtitle;
  final Widget child;

  /// 0.40 (neighbour) → 1.00 (active): the top card's hairline reads as
  /// physically on top of the stack (MOTION_HANDOFF §1.1 / §6).
  final double edgeLift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;

    final hairlineBase = DeckSurface.hairline(brightness);
    final hairline =
        hairlineBase.withValues(alpha: hairlineBase.a * edgeLift);

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12, left: 6, right: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: hairline),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 18, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label.toUpperCase(),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Quiet corner pip.
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: SuitIcon(
                              suit: suit,
                              color: DeckSurface.pip(brightness),
                              size: 16),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
              // Dark-only top-edge highlight, fading at the corners.
              if (brightness == Brightness.dark)
                Positioned(
                  top: 0,
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
