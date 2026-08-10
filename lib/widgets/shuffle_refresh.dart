import 'dart:math' as math;

import 'package:flutter/cupertino.dart'
    show CupertinoSliverRefreshControl, RefreshIndicatorMode;
import 'package:flutter/material.dart';

import '../core/theme/deck_motion.dart';
import '../features/home/playing_card.dart';
import 'suit_icon.dart';

/// Pull-to-refresh whose indicator is the deck "shuffle": ♠ ♥ ♦ ♣ spread out
/// of a stack as you pull, then riffle left→right while the work runs
/// (MOTION_HANDOFF §2). Wire [onRefresh] to real work only — the gesture must
/// be absent on screens with nothing to refresh.
///
/// Builds a [CustomScrollView]; callers hand over their scrollable content as
/// [slivers] (wrap plain widgets in a `SliverList`/`SliverToBoxAdapter`).
class ShuffleRefresh extends StatelessWidget {
  const ShuffleRefresh({
    super.key,
    required this.onRefresh,
    required this.slivers,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> slivers;

  static const double _trigger = 88;
  static const double _extent = 60;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          refreshTriggerPullDistance: _trigger,
          refreshIndicatorExtent: _extent,
          // Keep the shuffle visible ≥700 ms even if the work returns instantly
          // — below that it reads as a glitch (§2.3).
          onRefresh: () async {
            await Future.wait([
              onRefresh(),
              Future<void>.delayed(const Duration(milliseconds: 700)),
            ]);
          },
          builder: (context, mode, pulledExtent, triggerDistance, _) {
            return _ShuffleIndicator(
              mode: mode,
              pulledExtent: pulledExtent,
              triggerDistance: triggerDistance,
            );
          },
        ),
        ...slivers,
      ],
    );
  }
}

const List<CardSuit> _suits = [
  CardSuit.spade,
  CardSuit.heart,
  CardSuit.diamond,
  CardSuit.club,
];

/// The four-suit indicator: finger-driven spread during the drag, a repeating
/// riffle while refreshing, a fade-out when done.
class _ShuffleIndicator extends StatefulWidget {
  const _ShuffleIndicator({
    required this.mode,
    required this.pulledExtent,
    required this.triggerDistance,
  });

  final RefreshIndicatorMode mode;
  final double pulledExtent;
  final double triggerDistance;

  @override
  State<_ShuffleIndicator> createState() => _ShuffleIndicatorState();
}

class _ShuffleIndicatorState extends State<_ShuffleIndicator>
    with SingleTickerProviderStateMixin {
  static const double _suitSize = 14;
  static const double _gap = 10;
  static const double _slot = _suitSize + _gap; // 24 dp between suit centres
  static const double _lift = 6;
  static const int _loopMs = 540; // 420 ms riffle + 120 ms pause

  late final AnimationController _riffle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _loopMs),
  );
  bool _armed = false;

  @override
  void didUpdateWidget(_ShuffleIndicator old) {
    super.didUpdateWidget(old);
    // Fire the arm haptic once, on the drag→armed crossing (§2.2).
    final armed = widget.mode == RefreshIndicatorMode.armed;
    if (armed && !_armed) Motion.tick();
    _armed = armed;

    final running = widget.mode == RefreshIndicatorMode.armed ||
        widget.mode == RefreshIndicatorMode.refresh;
    if (running && !_riffle.isAnimating && !Motion.of(context).reduced) {
      _riffle.repeat();
    } else if (!running && _riffle.isAnimating) {
      _riffle.stop();
    }
  }

  @override
  void dispose() {
    _riffle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduced = Motion.of(context).reduced;
    final mode = widget.mode;

    // Drag progress 0→1; clamped so over-pull adds nothing.
    final p = widget.triggerDistance == 0
        ? 0.0
        : (widget.pulledExtent / widget.triggerDistance).clamp(0.0, 1.0);
    final refreshing = mode == RefreshIndicatorMode.armed ||
        mode == RefreshIndicatorMode.refresh;
    final done = mode == RefreshIndicatorMode.done;

    // Fade the whole row out as it collapses when done.
    final rowOpacity = done
        ? (widget.pulledExtent / widget.triggerDistance).clamp(0.0, 1.0)
        : 1.0;

    return Center(
      child: Opacity(
        opacity: rowOpacity,
        child: SizedBox(
          height: 44,
          child: AnimatedBuilder(
            animation: _riffle,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < _suits.length; i++)
                    _suit(i, p, refreshing, reduced, scheme),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _suit(
    int i,
    double p,
    bool refreshing,
    bool reduced,
    ColorScheme scheme,
  ) {
    // Row slot centre, measured from the row centre.
    final slotX = (i - 1.5) * _slot;

    double dx;
    double dy = 0;
    double rotation;
    double opacity;
    Color color;

    if (refreshing) {
      // Riffle: each suit lifts sequentially, lifted one in `primary`.
      dx = slotX;
      rotation = 0;
      opacity = 1;
      if (reduced) {
        dy = 0;
        color = scheme.primary; // static row, all primary (§2.4)
      } else {
        final elapsed = _riffle.value * _loopMs - i * 90; // ms into this suit
        final bump = (elapsed >= 0 && elapsed <= 180)
            ? math.sin(math.pi * (elapsed / 180))
            : 0.0;
        dy = -_lift * bump;
        color = Color.lerp(scheme.outline, scheme.primary, bump)!;
      }
    } else {
      // Drag: spread from a centred, tilted stack to an even upright row.
      dx = slotX * p;
      rotation = (i.isEven ? 1 : -1) * (math.pi / 30) * (1 - p); // ±6°
      opacity = 0.40 + 0.60 * p;
      color = scheme.outline;
    }

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: opacity,
          child: SuitIcon(suit: _suits[i], color: color, size: _suitSize),
        ),
      ),
    );
  }
}
