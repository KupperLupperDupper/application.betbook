import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/money/money_format.dart';
import '../../core/stats/summaries.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/data_providers.dart';
import '../../providers/rates_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/net_text.dart';
import '../../widgets/shuffle_refresh.dart';
import '../../widgets/skeleton.dart';
import 'widgets/site_tile.dart';

class SitesCard extends ConsumerWidget {
  const SitesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sitesAsync = ref.watch(sitesProvider);
    final portfolio = ref.watch(portfolioProvider);
    final locale = ref.watch(settingsProvider.select((s) => s.languageCode));

    return sitesAsync.when(
      loading: () => const SkeletonSwitcher(
        loading: true,
        skeleton: _SitesSkeleton(),
        child: SizedBox.shrink(),
      ),
      error: (e, _) => Center(child: Text(l10n.commonError)),
      data: (sites) {
        if (sites.isEmpty) {
          return EmptyState(
            title: l10n.sitesEmptyTitle,
            message: l10n.sitesEmptyBody,
            actionLabel: l10n.siteAdd,
            onAction: () => context.push(Routes.newSite),
          );
        }
        if (portfolio == null) {
          return const SkeletonSwitcher(
            loading: true,
            skeleton: _SitesSkeleton(),
            child: SizedBox.shrink(),
          );
        }
        final base = portfolio.baseCurrency;
        return SkeletonSwitcher(
          loading: false,
          skeleton: const _SitesSkeleton(),
          child: ShuffleRefresh(
            onRefresh: () async {
              await ref.read(ratesUpdaterProvider).refreshNow();
            },
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.sitesCount(sites.length),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                          NetText(
                            value: portfolio.netBase,
                            text: formatMajor(portfolio.netBase, base,
                                localeName: locale, withSign: true),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                    for (final (i, site) in sites.indexed)
                      SiteTile(
                        site: site,
                        summary: portfolio.siteSummaries[site.id] ??
                            SiteSummary(
                              siteId: site.id,
                              currencyCode: site.currencyCode,
                              depositedMinor: 0,
                              withdrawnMinor: 0,
                              transactionCount: 0,
                            ),
                        localeName: locale,
                        countUpIndex: i,
                        countUpListRow: true,
                        onTap: () => context.push(Routes.siteDetail(site.id)),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton for the Sites deck card (MOTION_HANDOFF §4.3) — five rows.
class _SitesSkeleton extends StatelessWidget {
  const _SitesSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cw = constraints.maxWidth - 32; // 16 padding each side
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SkeletonBlock(width: cw * 0.34, height: 12),
            const SizedBox(height: 12),
            for (var i = 0; i < 5; i++) _SkeletonSiteRow(contentWidth: cw),
          ],
        );
      },
    );
  }
}

class _SkeletonSiteRow extends StatelessWidget {
  const _SkeletonSiteRow({required this.contentWidth});

  final double contentWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          const SkeletonBlock(width: 32, height: 44, radius: 6),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: contentWidth * 0.46, height: 16),
                const SizedBox(height: 6),
                SkeletonBlock(width: contentWidth * 0.28, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonBlock(width: contentWidth * 0.18, height: 16),
              const SizedBox(height: 6),
              SkeletonBlock(width: contentWidth * 0.10, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}
