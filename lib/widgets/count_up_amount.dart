import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../core/theme/deck_motion.dart';
import '../core/theme/money_colors.dart';

/// Animated money figure (MOTION_HANDOFF §5).
///
/// Counts the displayed number up from 0 → value on first mount, and from the
/// previously-displayed value → the new value on later changes (§5.1). When the
/// sign flips it runs a two-leg colour lerp through `neutral` (§5.2). Sign and
/// trend icon are fixed to the final state at frame 0 so only the digits move.
///
/// A [secondary] figure is part of the staggered count-up wave (§5.3): it only
/// counts the digits — colour and sign are the final state from frame 0, it
/// never crosses zero, and it does not announce a `liveRegion` (only the hero
/// does). Pass [delay] for its place in the wave and [duration] for its length
/// (`Motion.of(context).countUpDelay(i)` / `countUpFor(i)`); a [duration] of
/// `Duration.zero` renders the final value immediately (used past the cap).
class CountUpAmount extends StatefulWidget {
  const CountUpAmount({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.iconSize = 30,
    this.showIcon = true,
    this.secondary = false,
    this.delay = Duration.zero,
    this.duration,
    this.color,
  });

  /// Raw amount in BASE major units.
  final double value;

  /// Formats a raw amount into the full display string (sign + currency).
  final String Function(double) format;

  /// Base text style for the figure. Tabular figures are forced on.
  final TextStyle? style;
  final double iconSize;
  final bool showIcon;

  /// Secondary figures animate the digits only: colour + sign are final from
  /// frame 0, no zero-crossing lerp, no `liveRegion` announcement.
  final bool secondary;

  /// Wait this long after the trigger before counting (the wave stagger).
  final Duration delay;

  /// Overrides the count duration. Defaults to the hero 400 ms (`Motion.countUp`).
  /// `Duration.zero` renders the final value immediately (no animation).
  final Duration? duration;

  /// Fixed final colour. When null a net figure uses `money.forAmount(value)`;
  /// pass `onSurface` for neutral totals that must never take a profit/loss hue.
  final Color? color;

  @override
  State<CountUpAmount> createState() => _CountUpAmountState();
}

class _CountUpAmountState extends State<CountUpAmount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  // Endpoints of the current count. At rest, _from == _to == displayed value.
  double _from = 0;
  late double _to;

  /// The initial 0 → value count is never treated as a zero-crossing.
  bool _firstAnim = true;
  bool _initialized = false;

  static int _sign(double v) => v > 0 ? 1 : (v < 0 ? -1 : 0);

  @override
  void initState() {
    super.initState();
    _to = widget.value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _startCount(Motion.of(context));
  }

  @override
  void didUpdateWidget(covariant CountUpAmount old) {
    super.didUpdateWidget(old);
    // Ignore rebuilds where the formatted value is unchanged.
    if (widget.format(widget.value) == widget.format(_to)) {
      if (widget.value != _to) {
        _from = widget.value;
        _to = widget.value;
      }
      return;
    }
    _firstAnim = false;
    _from = _displayedValue();
    _to = widget.value;
    _startCount(Motion.of(context));
  }

  /// Starts (or, after [CountUpAmount.delay], schedules) the count, honouring
  /// reduced motion and a zero duration by snapping to the final value.
  void _startCount(Motion motion) {
    final dur = widget.duration ?? motion.countUp;
    if (motion.reduced || dur == Duration.zero) {
      _from = _to;
      _controller.value = 1;
      return;
    }
    _controller.duration = dur;
    if (widget.delay == Duration.zero) {
      _controller.forward(from: 0);
    } else {
      _controller.value = 0; // hold the start value until the stagger elapses
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward(from: 0);
      });
    }
  }

  /// Current animated figure value under the entrance curve.
  double _displayedValue() {
    final t = Motion.entrance.transform(_controller.value);
    return lerpDouble(_from, _to, t)!;
  }

  /// Two-leg colour lerp old → neutral → new, neutral forced at t = 0.5.
  Color _crossingColor(Color from, Color neutral, Color to, double t) {
    final e = Curves.easeInOutSine.transform(t.clamp(0.0, 1.0));
    return e <= 0.5
        ? Color.lerp(from, neutral, e / 0.5)!
        : Color.lerp(neutral, to, (e - 0.5) / 0.5)!;
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final money = context.money;

    final newColor = widget.color ?? money.forAmount(widget.value);
    final oldColor = widget.color ?? money.forAmount(_from);
    // Secondary figures never animate colour — only the hero may cross zero.
    final crossing =
        !widget.secondary && !_firstAnim && _sign(_from) != _sign(_to);

    // Sign + icon are held at the final state (§5.2). Exact zero is flat.
    final finalIcon = widget.value == 0
        ? Icons.trending_flat_rounded
        : money.iconForAmount(widget.value);

    final figureStyle = (widget.style ?? const TextStyle())
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    // Reserve width against the wider of the two endpoints so the block does
    // not resize mid-count; keep it left-anchored.
    final fromStr = widget.format(_from);
    final toStr = widget.format(_to);
    final sizer = fromStr.length >= toStr.length ? fromStr : toStr;

    final animated = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = (motion.reduced || !crossing)
            ? newColor
            : _crossingColor(
                oldColor,
                money.neutral,
                newColor,
                motion.zeroCrossing == Duration.zero
                    ? 1.0
                    : (_controller.value *
                            motion.countUp.inMilliseconds /
                            motion.zeroCrossing.inMilliseconds)
                        .clamp(0.0, 1.0),
              );
        final value = _displayedValue();
        final figure = Stack(
          alignment: Alignment.centerLeft,
          children: [
            ExcludeSemantics(
              child: Opacity(opacity: 0, child: Text(sizer, style: figureStyle)),
            ),
            ExcludeSemantics(
              child: Text(
                widget.format(value),
                style: figureStyle.copyWith(color: color),
              ),
            ),
          ],
        );
        if (!widget.showIcon) return figure;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(finalIcon, color: color, size: widget.iconSize),
            const SizedBox(width: 8),
            Flexible(child: figure),
          ],
        );
      },
    );

    // The animating text is excluded; a sibling label carries the value. Only
    // the hero announces on change (liveRegion); secondaries are read on focus.
    return Semantics(
      liveRegion: !widget.secondary,
      label: widget.format(widget.value),
      child: animated,
    );
  }
}
