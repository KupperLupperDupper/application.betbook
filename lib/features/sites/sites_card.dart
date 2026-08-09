import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/money/money_format.dart';
import '../../core/stats/summaries.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/net_text.dart';
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
      loading: () => const Center(child: CircularProgressIndicator()),
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
          return const Center(child: CircularProgressIndicator());
        }
        final base = portfolio.baseCurrency;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.sitesCount(sites.length),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            for (final site in sites)
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
                onTap: () => context.push(Routes.siteDetail(site.id)),
              ),
          ],
        );
      },
    );
  }
}
