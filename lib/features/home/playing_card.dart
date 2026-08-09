import 'package:flutter/material.dart';

import '../../widgets/suit_icon.dart';

/// The four playing-card suits used as section identity/markers.
/// Deck order matches the design: Dashboard ♠ · Sites ♥ · Stats ♦ · Settings ♣.
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
  });

  final CardSuit suit;
  final String label;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12, left: 6, right: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
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
                      child: SuitIcon(suit: suit, color: scheme.outline, size: 16),
                    ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
