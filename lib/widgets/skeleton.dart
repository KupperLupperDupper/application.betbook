import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../core/theme/deck_motion.dart';
import '../l10n/l10n_ext.dart';

/// Claude Design v3 "skeleton blocks" loaders (MOTION_HANDOFF §4.2 + §4.3).
///
/// A [SkeletonSwitcher] owns one shimmer driver ([SkeletonSweep]) per skeleton
/// subtree; every [SkeletonBlock] beneath it shares that single sweep so the
/// highlight reads as one coordinated pass across the screen rather than each
/// block twinkling on its own. Reduced motion collapses to a flat fill with an
/// instant swap — no band, no cross-fade.

/// Shared shimmer driver. Repeats over `shimmerSweep + shimmerPause` and exposes
/// its progress to descendant [SkeletonBlock]s via an inherited scope. One
/// controller per subtree — never one per block.
class SkeletonSweep extends StatefulWidget {
  const SkeletonSweep({super.key, required this.child});

  final Widget child;

  static _SweepScope? _maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SweepScope>();

  @override
  State<SkeletonSweep> createState() => _SkeletonSweepState();
}

class _SkeletonSweepState extends State<SkeletonSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this);

  /// Fraction of the cycle spent sweeping; the remainder is the rest pause.
  double _sweepFraction = 1.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = Motion.of(context);
    final sweepMs = motion.shimmerSweep.inMilliseconds;
    final pauseMs = motion.shimmerPause.inMilliseconds;
    final totalMs = sweepMs + pauseMs;
    // Reduced motion (durations collapse to zero) → no sweep at all.
    if (motion.reduced || totalMs == 0) {
      _controller.stop();
      _sweepFraction = 1.0;
      return;
    }
    _controller.duration = Duration(milliseconds: totalMs);
    _sweepFraction = sweepMs / totalMs;
    if (!_controller.isAnimating) _controller.repeat();
  }

  /// Sweep progress 0→1 during the sweep phase, parked at 1 (band off-screen)
  /// through the pause.
  double get _progress {
    if (!_controller.isAnimating) return 1.0;
    final t = _controller.value;
    return t <= _sweepFraction ? t / _sweepFraction : 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SweepScope(
      animation: _controller,
      progressOf: () => _progress,
      child: widget.child,
    );
  }
}

class _SweepScope extends InheritedWidget {
  const _SweepScope({
    required this.animation,
    required this.progressOf,
    required super.child,
  });

  /// Ticks every frame; [SkeletonBlock] repaints against it.
  final Listenable animation;

  /// Current sweep progress, read at paint time.
  final double Function() progressOf;

  @override
  bool updateShouldNotify(_SweepScope oldWidget) =>
      animation != oldWidget.animation;
}

/// A rounded rectangle filled with `surfaceContainerHigh`, painting a moving
/// highlight band (40% of its width, transparent→highlight→transparent) driven
/// by the shared [SkeletonSweep]. Reduced motion → base fill only.
///
/// [width] is absolute; [widthFactor] is a fraction of the available width.
/// Provide at most one; omitting both fills the available width.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    this.widthFactor,
    required this.height,
    this.radius = SkeletonTokens.radiusLine,
  }) : assert(width == null || widthFactor == null,
            'Provide width or widthFactor, not both');

  final double? width;
  final double? widthFactor;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = theme.colorScheme.surfaceContainerHigh;
    final highlight = SkeletonTokens.highlight(theme.brightness);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final scope = reduced ? null : SkeletonSweep._maybeOf(context);

    final Widget paint;
    if (scope == null) {
      paint = CustomPaint(
        size: Size.infinite,
        painter: _BlockPainter(fill: fill, highlight: highlight, radius: radius),
      );
    } else {
      paint = AnimatedBuilder(
        animation: scope.animation,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _BlockPainter(
            fill: fill,
            highlight: highlight,
            radius: radius,
            progress: scope.progressOf(),
          ),
        ),
      );
    }

    if (widthFactor != null) {
      return FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: SizedBox(height: height, child: paint),
      );
    }
    return SizedBox(width: width ?? double.infinity, height: height, child: paint);
  }
}

class _BlockPainter extends CustomPainter {
  _BlockPainter({
    required this.fill,
    required this.highlight,
    required this.radius,
    this.progress,
  });

  final Color fill;
  final Color highlight;
  final double radius;

  /// Null (reduced motion) or >= 1 (rest pause) → no band painted.
  final double? progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    canvas.clipRRect(rrect);
    canvas.drawRect(Offset.zero & size, Paint()..color = fill);

    final p = progress;
    if (p == null || p >= 1.0) return;

    final bandWidth = size.width * SkeletonTokens.bandFraction;
    final start = lerpDouble(-bandWidth, size.width, p)!;
    final bandRect = Rect.fromLTWH(start, 0, bandWidth, size.height);
    // Clamp tiling keeps everything outside the band transparent.
    final shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        highlight.withValues(alpha: 0),
        highlight,
        highlight.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(bandRect);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_BlockPainter old) =>
      old.progress != progress ||
      old.fill != fill ||
      old.highlight != highlight ||
      old.radius != radius;
}

/// Shows [skeleton] while [loading], enforcing a 400 ms minimum visible time
/// (below that — if data is already ready at mount — the skeleton is skipped and
/// [child] shows directly), then cross-fades to [child] over 150 ms. The
/// skeleton subtree is excluded from semantics and announced once as a loading
/// live region. Reduced motion → no sweep, instant swap.
class SkeletonSwitcher extends StatefulWidget {
  const SkeletonSwitcher({
    super.key,
    required this.loading,
    required this.skeleton,
    required this.child,
  });

  final bool loading;
  final Widget skeleton;
  final Widget child;

  @override
  State<SkeletonSwitcher> createState() => _SkeletonSwitcherState();
}

class _SkeletonSwitcherState extends State<SkeletonSwitcher> {
  late bool _showSkeleton;
  DateTime? _shownAt;
  Timer? _minTimer;

  static const Duration _minVisible = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _showSkeleton = widget.loading;
    if (_showSkeleton) _shownAt = DateTime.now();
  }

  @override
  void didUpdateWidget(SkeletonSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading && !_showSkeleton) {
      _minTimer?.cancel();
      setState(() {
        _showSkeleton = true;
        _shownAt = DateTime.now();
      });
    } else if (!widget.loading && _showSkeleton) {
      final shownAt = _shownAt ?? DateTime.now();
      final remaining = _minVisible - DateTime.now().difference(shownAt);
      if (remaining <= Duration.zero) {
        setState(() => _showSkeleton = false);
      } else {
        _minTimer?.cancel();
        _minTimer = Timer(remaining, () {
          if (mounted && !widget.loading) {
            setState(() => _showSkeleton = false);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crossFade = Motion.of(context).skeletonCrossFade;
    final skeleton = Semantics(
      liveRegion: true,
      label: context.l10n.commonLoading,
      child: ExcludeSemantics(
        child: SkeletonSweep(child: widget.skeleton),
      ),
    );
    return AnimatedSwitcher(
      duration: crossFade,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showSkeleton
          ? KeyedSubtree(key: const ValueKey('skeleton'), child: skeleton)
          : KeyedSubtree(key: const ValueKey('content'), child: widget.child),
    );
  }
}
