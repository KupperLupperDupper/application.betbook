import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/deck_motion.dart';
import '../../l10n/l10n_ext.dart';
import '../../widgets/suit_icon.dart';
import '../dashboard/dashboard_card.dart';
import '../settings/settings_card.dart';
import '../sites/sites_card.dart';
import '../stats/stats_card.dart';
import 'playing_card.dart';

/// The deck's deal-in plays once per app process (cold start / after onboarding).
bool _deckDealtThisProcess = false;

class _Section {
  const _Section({
    required this.suit,
    required this.label,
    required this.child,
  });
  final CardSuit suit;
  final String Function(BuildContext) label;
  final Widget child;
}

/// The app's home: the four top-level sections are a deck of playing cards the
/// user swipes between, with a bottom suit indicator. Detail flows push on top.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with TickerProviderStateMixin {
  final _controller =
      PageController(viewportFraction: AppDeck.viewportFraction);
  int _index = 0;

  // Deal-in animation (§1.3). Total covers card motion + indicator + FAB.
  late final AnimationController _dealIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  bool _dealDecided = false;

  // Settle emphasis (§1.5): a 420 ms hairline pulse on the card that just
  // landed, fired concurrently with the settle haptic. Only the card at
  // [_settleIndex] reacts.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  int _settleIndex = 0;

  void _emphasise(int i) {
    if (!Motion.of(context).settleEmphasis) return;
    _settleIndex = i;
    _settle.forward(from: 0.0);
  }

  // Deck order: Dashboard ♠ · Sites ♥ · Stats ♦ · Settings ♣
  static final _sections = <_Section>[
    _Section(
      suit: CardSuit.spade,
      label: (c) => c.l10n.navDashboard,
      child: const DashboardCard(),
    ),
    _Section(
      suit: CardSuit.heart,
      label: (c) => c.l10n.navSites,
      child: const SitesCard(),
    ),
    _Section(
      suit: CardSuit.diamond,
      label: (c) => c.l10n.navStats,
      child: const StatsCard(),
    ),
    _Section(
      suit: CardSuit.club,
      label: (c) => c.l10n.navSettings,
      child: const SettingsCard(),
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dealDecided) return;
    _dealDecided = true;
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (_deckDealtThisProcess || reduced) {
      _dealIn.value = 1.0;
    } else {
      _deckDealtThisProcess = true;
      // Start once the deck is actually painted (and the native splash gone),
      // otherwise a slow cold start consumes the animation behind the splash.
      _dealIn.value = 0.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // The Dashboard card lands last — flick its hairline as it settles.
          _dealIn.forward().whenComplete(() {
            if (mounted) _emphasise(_index);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    _dealIn.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    Motion.tick();
    final m = Motion.of(context);
    if (m.reduced) {
      _controller.jumpToPage(i);
      return;
    }
    final far = (i - _index).abs() >= 2;
    _controller.animateToPage(
      i,
      duration: far ? m.deckPageJumpFar : m.deckPageJump,
      curve: Motion.entrance,
    );
  }

  void _onPageChanged(int i) {
    if (i != _index) {
      Motion.tick();
      _emphasise(i);
    }
    setState(() => _index = i);
    // A swipe cancels any in-flight deal-in and hands control to the PageView.
    if (_dealIn.isAnimating) {
      _dealIn.animateTo(1.0, duration: const Duration(milliseconds: 120));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Dashboard → compact "add transaction"; Sites → extended "add site".
    Widget? fab;
    if (_index == 0) {
      fab = FloatingActionButton(
        heroTag: null,
        onPressed: () => context.push(Routes.newTransaction),
        child: const Icon(Icons.add_rounded),
      );
    } else if (_index == 1) {
      fab = FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => context.push(Routes.newSite),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.siteAdd),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _sections.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, i) {
                final section = _sections[i];
                return _AnimatedDeckItem(
                  controller: _controller,
                  dealIn: _dealIn,
                  settle: _settle,
                  settleIndex: _settleIndex,
                  index: i,
                  currentIndex: _index,
                  suit: section.suit,
                  label: section.label(context),
                  content: section.child,
                );
              },
            ),
            // FAB sits centred in its own band ABOVE the suit indicator so they
            // never overlap, whatever the FAB's width.
            if (fab != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 78,
                child: Center(
                  child: _DealInFade(
                    listenable: _dealIn,
                    start: 640 / 800,
                    end: 800 / 800,
                    scaleFrom: 0.9,
                    child: fab,
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: _DealInFade(
                  listenable: _dealIn,
                  start: 590 / 800,
                  end: 770 / 800,
                  child: _SuitIndicator(
                    suits: [for (final s in _sections) s.suit],
                    index: _index,
                    onTap: _goTo,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades (and optionally scales) a child in over a window of the deal-in.
class _DealInFade extends StatelessWidget {
  const _DealInFade({
    required this.listenable,
    required this.start,
    required this.end,
    required this.child,
    this.scaleFrom = 1.0,
  });

  final Animation<double> listenable;
  final double start;
  final double end;
  final double scaleFrom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: listenable,
      child: child,
      builder: (context, child) {
        final t = ((listenable.value - start) / (end - start)).clamp(0.0, 1.0);
        final e = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: e,
          child: Transform.scale(scale: lerpDouble(scaleFrom, 1.0, e), child: child),
        );
      },
    );
  }
}

/// Deck card with the swipe transform (scale/opacity/tilt/edge-lift) and the
/// one-time deal-in entry composed on top.
class _AnimatedDeckItem extends StatelessWidget {
  const _AnimatedDeckItem({
    required this.controller,
    required this.dealIn,
    required this.settle,
    required this.settleIndex,
    required this.index,
    required this.currentIndex,
    required this.suit,
    required this.label,
    required this.content,
  });

  final PageController controller;
  final Animation<double> dealIn;
  final Animation<double> settle;
  final int settleIndex;
  final int index;
  final int currentIndex;
  final CardSuit suit;
  final String label;
  final Widget content;

  /// Maps the 420 ms settle controller (0→1) to a hairline intensity that
  /// rises (140 ms, easeOutCubic), holds (60 ms), then falls (220 ms,
  /// easeOutSine) — the §1.5 emphasis envelope.
  double _settleIntensity(double v) {
    const inEnd = 140 / 420;
    const holdEnd = 200 / 420;
    if (v <= inEnd) return Curves.easeOutCubic.transform(v / inEnd);
    if (v <= holdEnd) return 1.0;
    final out = (v - holdEnd) / (1 - holdEnd);
    return 1.0 - Motion.settleRelease.transform(out.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.of(context).reduced;
    return AnimatedBuilder(
      animation: Listenable.merge([controller, dealIn, settle]),
      child: content,
      builder: (context, content) {
        final page = (controller.hasClients && controller.position.haveDimensions)
            ? (controller.page ?? currentIndex.toDouble())
            : currentIndex.toDouble();
        final delta = page - index;
        final offset = delta.abs().clamp(0.0, 1.0);

        var scale = reduced ? 1.0 : DeckTransform.scale(offset);
        var opacity = reduced ? 1.0 : DeckTransform.opacity(offset);
        var tilt = reduced ? 0.0 : DeckTransform.tilt(delta);
        var edgeLift = reduced
            ? 1.0
            : DeckTransform.hairlineOpacity(offset).clamp(0.40, 1.0);
        // Neighbours sit lower in the stack (§1.1 stack drop).
        var translate =
            reduced ? Offset.zero : Offset(0, DeckTransform.stackDrop(offset));

        // Deal-in entry (back-to-front: ♣ ♦ ♥ ♠). Skipped when reduced.
        if (!reduced && dealIn.value < 1.0) {
          final vMs = dealIn.value * 800;
          final delayMs = 110.0 * (3 - index);
          final tEntry = ((vMs - delayMs) / 460).clamp(0.0, 1.0);
          final e = Curves.easeOutCubic.transform(tEntry);
          scale *= lerpDouble(DealIn.fromScale, 1.0, e)!;
          opacity *= e;
          tilt += lerpDouble(DealIn.fromRotation, 0.0, e)!;
          translate += Offset(
            DealIn.fromOffset.dx * (1 - e),
            DealIn.fromOffset.dy * (1 - e),
          );
        }

        final settleValue = (!reduced && index == settleIndex)
            ? _settleIntensity(settle.value)
            : 0.0;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: translate,
            child: Transform.rotate(
              angle: tilt,
              alignment: Alignment.bottomCenter,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.bottomCenter,
                child: PlayingCard(
                  suit: suit,
                  label: label,
                  edgeLift: edgeLift,
                  settle: settleValue,
                  child: content!,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Centred ♠ ♥ ♦ ♣ row; active glyph larger and in primary, others outline.
class _SuitIndicator extends StatelessWidget {
  const _SuitIndicator({
    required this.suits,
    required this.index,
    required this.onTap,
  });

  final List<CardSuit> suits;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < suits.length; i++)
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onTap(i),
              child: SizedBox(
                width: 48,
                height: 40,
                child: Center(
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: i == index ? 1.25 : 1.0,
                    child: SuitIcon(
                      suit: suits[i],
                      color: i == index ? scheme.primary : scheme.outline,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
