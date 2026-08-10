import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/deck_motion.dart';
import '../features/home/playing_card.dart';
import 'suit_icon.dart';

enum SuitLoaderSize { small, medium, large }

/// On-brand loader (MOTION_HANDOFF §4.1): ♠ ♥ ♦ ♣ in `primary`, each pulsing
/// opacity 0.35→1.0 + scale 0.92→1.0 with a staggered easeInOutSine loop.
/// Reduced motion → four static suits at full opacity. For genuinely blocking
/// work only (import/export/restore) — never for a list about to appear.
class SuitLoader extends StatefulWidget {
  const SuitLoader({super.key, this.size = SuitLoaderSize.medium, this.label});

  final SuitLoaderSize size;
  final String? label;

  @override
  State<SuitLoader> createState() => _SuitLoaderState();
}

class _SuitLoaderState extends State<SuitLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 880),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double get _glyph => switch (widget.size) {
        SuitLoaderSize.small => 12,
        SuitLoaderSize.medium => 16,
        SuitLoaderSize.large => 22,
      };
  double get _gap => switch (widget.size) {
        SuitLoaderSize.small => 8,
        SuitLoaderSize.medium => 12,
        SuitLoaderSize.large => 16,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final reduced = Motion.of(context).reduced;

    // Loops stop when animations are disabled.
    if (reduced) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }

    Widget row(double Function(int) opacityOf, double Function(int) scaleOf) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < CardSuit.values.length; i++) ...[
            if (i > 0) SizedBox(width: _gap),
            Opacity(
              opacity: opacityOf(i),
              child: Transform.scale(
                scale: scaleOf(i),
                child: SuitIcon(
                    suit: CardSuit.values[i], color: color, size: _glyph),
              ),
            ),
          ],
        ],
      );
    }

    final Widget suits = reduced
        ? row((_) => 1, (_) => 1)
        : RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                double v(int i) {
                  // Staggered sine pulse (out-and-back, easeInOutSine profile).
                  final phase = _c.value * 2 * math.pi - i * (2 * math.pi * 0.125);
                  return (math.sin(phase) + 1) / 2;
                }

                return row(
                  (i) => 0.35 + 0.65 * v(i),
                  (i) => 0.92 + 0.08 * v(i),
                );
              },
            ),
          );

    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          suits,
          if (widget.label != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.label!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
