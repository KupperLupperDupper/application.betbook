import 'package:flutter/material.dart';

/// The four playing-card suits used as section identity/markers.
enum CardSuit {
  spade('♠'),
  heart('♥'),
  diamond('♦'),
  club('♣');

  const CardSuit(this.glyph);
  final String glyph;

  /// Traditional colouring: hearts/diamonds red, spades/clubs ink.
  Color accent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRed = this == CardSuit.heart || this == CardSuit.diamond;
    return isRed ? const Color(0xFFD5384B) : scheme.onSurface;
  }
}

/// A section presented as a playing card: rounded, softly elevated, with the
/// title + suit marked in opposite corners like a real card.
class PlayingCard extends StatelessWidget {
  const PlayingCard({
    super.key,
    required this.suit,
    required this.title,
    required this.child,
  });

  final CardSuit suit;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = suit.accent(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Bottom-right corner marker (rotated, like a real card).
              Positioned(
                right: 16,
                bottom: 16,
                child: Transform.rotate(
                  angle: 3.14159,
                  child: _CornerMark(suit: suit, accent: accent),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Row(
                      children: [
                        _CornerMark(suit: suit, accent: accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerMark extends StatelessWidget {
  const _CornerMark({required this.suit, required this.accent});
  final CardSuit suit;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          suit.glyph,
          style: TextStyle(fontSize: 22, height: 1, color: accent),
        ),
      ],
    );
  }
}
