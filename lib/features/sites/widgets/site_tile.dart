import 'package:flutter/material.dart';

import '../../../core/money/money_format.dart';
import '../../../core/stats/summaries.dart';
import '../../../data/database/database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/currency_chip.dart';
import '../../../widgets/mini_card_avatar.dart';
import '../../../widgets/net_text.dart';

/// A single site row: colour avatar, name, transaction count, currency badge,
/// and net result in the site's own currency. Matches the design's site row.
class SiteTile extends StatelessWidget {
  const SiteTile({
    super.key,
    required this.site,
    required this.summary,
    required this.localeName,
    this.onTap,
  });

  final Site site;
  final SiteSummary summary;
  final String localeName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      onTap: onTap,
      leading: MiniCardAvatar(
        siteId: site.id,
        name: site.name,
        colorValue: site.colorValue,
      ),
      title: Text(
        site.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        context.l10n.siteTransactionCount(summary.transactionCount),
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurrencyChip(code: site.currencyCode),
          const SizedBox(width: 10),
          NetText(
            value: summary.netMinor,
            text: formatMinorPlain(
              summary.netMinor,
              localeName: localeName,
              withSign: true,
            ),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
