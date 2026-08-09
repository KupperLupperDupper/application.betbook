import 'package:flutter/material.dart';

import '../../../core/money/money_format.dart';
import '../../../core/stats/summaries.dart';
import '../../../data/database/database.dart';
import '../../../widgets/net_text.dart';

/// A single site row: colour avatar, name, transaction count, and net result
/// in the site's own currency. Shared by the dashboard and the sites list.
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
    final color = Color(site.colorValue);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.18),
        foregroundColor: color,
        child: Text(
          site.name.isNotEmpty
              ? site.name.characters.first.toUpperCase()
              : '?',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(
        site.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${site.currencyCode} · ${summary.transactionCount}',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: NetText(
        value: summary.netMinor,
        text: formatMinor(
          summary.netMinor,
          site.currencyCode,
          localeName: localeName,
          withSign: true,
        ),
        style: theme.textTheme.titleSmall,
      ),
    );
  }
}
