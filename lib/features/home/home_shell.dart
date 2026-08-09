import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/l10n_ext.dart';
import '../../widgets/suit_icon.dart';
import '../dashboard/dashboard_card.dart';
import '../settings/settings_card.dart';
import '../sites/sites_card.dart';
import '../stats/stats_card.dart';
import 'playing_card.dart';

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

class _HomeShellState extends ConsumerState<HomeShell> {
  final _controller =
      PageController(viewportFraction: AppDeck.viewportFraction);
  int _index = 0;

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    HapticFeedback.selectionClick();
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Dashboard → add transaction; Sites → add site; others → none.
    Widget? fab;
    if (_index == 0) {
      fab = FloatingActionButton.extended(
        onPressed: () => context.push(Routes.newTransaction),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.txAdd),
      );
    } else if (_index == 1) {
      fab = FloatingActionButton.extended(
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
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final section = _sections[i];
                return _AnimatedDeckItem(
                  controller: _controller,
                  index: i,
                  child: PlayingCard(
                    suit: section.suit,
                    label: section.label(context),
                    child: section.child,
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(
                child: _SuitIndicator(
                  suits: [for (final s in _sections) s.suit],
                  index: _index,
                  onTap: _goTo,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: fab,
    );
  }
}

/// Applies a subtle scale/opacity falloff to non-focused cards.
class _AnimatedDeckItem extends StatelessWidget {
  const _AnimatedDeckItem({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        var delta = 0.0;
        if (controller.hasClients && controller.position.haveDimensions) {
          delta = (controller.page ?? controller.initialPage.toDouble()) - index;
        } else {
          delta = (controller.initialPage - index).toDouble();
        }
        final t = (1 - delta.abs()).clamp(0.0, 1.0);
        final scale = AppDeck.neighbourScale + (1 - AppDeck.neighbourScale) * t;
        final opacity =
            AppDeck.neighbourOpacity + (1 - AppDeck.neighbourOpacity) * t;
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: child,
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
