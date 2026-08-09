import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/stats/summaries.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/empty_state.dart';
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
            icon: Icons.sports_soccer_rounded,
            title: l10n.dashboardEmptyTitle,
            message: l10n.dashboardEmptyBody,
            actionLabel: l10n.siteAdd,
            onAction: () => context.push(Routes.newSite),
          );
        }
        if (portfolio == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: OutlinedButton.icon(
                onPressed: () => context.push(Routes.newSite),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.siteAdd),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
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
