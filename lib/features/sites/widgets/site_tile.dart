import 'package:flutter/material.dart';

import '../../../core/money/money_format.dart';
import '../../../core/stats/summaries.dart';
import '../../../core/theme/deck_motion.dart';
import '../../../core/theme/money_colors.dart';
import '../../../data/database/database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/count_up_amount.dart';
import '../../../widgets/currency_chip.dart';
import '../../../widgets/mini_card_avatar.dart';

/// A single site row: colour avatar, name, transaction count, currency badge,
/// and net result in the site's own currency. Matches the design's site row.
///
/// The net figure is part of the staggered count-up wave (MOTION_HANDOFF §5.3):
/// [countUpIndex] is its place in the wave. The trend icon and sign are fixed
/// to the final state; only the digits count.
class SiteTile extends StatelessWidget {
  const SiteTile({
    super.key,
    required this.site,
    required this.summary,
    required this.localeName,
    required this.countUpIndex,
    this.countUpListRow = false,
    this.onTap,
  });

  final Site site;
  final SiteSummary summary;
  final String localeName;

  /// Index of the net figure in the count-up wave (0 = hero). Beyond the cap
  /// the figure renders final immediately.
  final int countUpIndex;

  /// Sites list rows use the tighter row stagger (§5.3).
  final bool countUpListRow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final motion = Motion.of(context);
    final netColor = context.money.forAmount(summary.netMinor);
    final figureStyle =
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);

    // Directional icon carries the meaning alongside colour (never colour
    // alone); it is static, only the digits animate.
    final trendIcon = summary.netMinor > 0
        ? Icons.trending_up_rounded
        : summary.netMinor < 0
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;

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
          Icon(trendIcon,
              color: netColor, size: (figureStyle?.fontSize ?? 16) * 0.9),
          const SizedBox(width: 4),
          CountUpAmount(
            value: minorToMajor(summary.netMinor),
            format: (v) => formatMinorPlain(
              majorToMinor(v),
              localeName: localeName,
              withSign: true,
            ),
            style: figureStyle,
            secondary: true,
            showIcon: false,
            color: netColor,
            delay: motion.countUpDelay(countUpIndex, listRow: countUpListRow),
            duration: countUpIndex < Motion.countUpMaxFigures
                ? motion.countUpFor(countUpIndex)
                : Duration.zero,
          ),
        ],
      ),
    );
  }
}
