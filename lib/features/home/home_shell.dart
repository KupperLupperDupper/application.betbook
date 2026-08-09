import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/l10n_ext.dart';
import '../dashboard/dashboard_card.dart';
import '../settings/settings_card.dart';
import '../sites/sites_card.dart';
import '../stats/stats_card.dart';
import 'playing_card.dart';

/// One swipeable section, presented as a playing card.
class _Section {
  const _Section({
    required this.suit,
    required this.label,
    required this.child,
    required this.showAddFab,
  });
  final CardSuit suit;
  final String Function(BuildContext) label;
  final Widget child;
  final bool showAddFab;
}

/// The app's home: the four top-level sections are a deck of playing cards the
/// user swipes horizontally between. Detail flows are pushed on top as routes.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  final _controller =
      PageController(viewportFraction: AppDeck.viewportFraction);
  int _index = 0;

  static final _sections = <_Section>[
    _Section(
      suit: CardSuit.spade,
      label: (c) => c.l10n.navDashboard,
      child: const DashboardCard(),
      showAddFab: true,
    ),
    _Section(
      suit: CardSuit.diamond,
      label: (c) => c.l10n.navSites,
      child: const SitesCard(),
      showAddFab: true,
    ),
    _Section(
      suit: CardSuit.club,
      label: (c) => c.l10n.navStats,
      child: const StatsCard(),
      showAddFab: false,
    ),
    _Section(
      suit: CardSuit.heart,
      label: (c) => c.l10n.navSettings,
      child: const SettingsCard(),
      showAddFab: false,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showFab = _sections[_index].showAddFab;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SuitNavBar(
              sections: _sections,
              index: _index,
              onTap: _goTo,
            ),
            Expanded(
              child: PageView.builder(
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
                      title: section.label(context),
                      child: section.child,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => context.push(Routes.newTransaction),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.txAdd),
            )
          : null,
    );
  }
}

/// Applies a subtle scale/opacity falloff to non-focused cards so the deck
/// reads as a stack you're flipping through.
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
        final scale = AppDeck.neighbourScale +
            (1 - AppDeck.neighbourScale) * t;
        final opacity = AppDeck.neighbourOpacity +
            (1 - AppDeck.neighbourOpacity) * t;
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: child,
    );
  }
}

class _SuitNavBar extends StatelessWidget {
  const _SuitNavBar({
    required this.sections,
    required this.index,
    required this.onTap,
  });

  final List<_Section> sections;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          for (var i = 0; i < sections.length; i++)
            Expanded(
              child: _SuitTab(
                suit: sections[i].suit,
                label: sections[i].label(context),
                selected: i == index,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuitTab extends StatelessWidget {
  const _SuitTab({
    required this.suit,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final CardSuit suit;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? scheme.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                suit.glyph,
                style: TextStyle(
                  fontSize: 18,
                  height: 1,
                  color: selected ? suit.accent(context) : color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
