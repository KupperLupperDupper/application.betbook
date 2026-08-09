import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money/currency.dart';
import '../../data/database/database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_providers.dart';

/// Lets the user view and edit the exchange rates used to convert each site's
/// currency into their main currency for portfolio totals.
class ExchangeRatesScreen extends ConsumerWidget {
  const ExchangeRatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final base = ref.watch(settingsProvider.select((s) => s.baseCurrency));
    final ratesAsync = ref.watch(ratesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exchangeRatesTitle)),
      body: ratesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.commonError)),
        data: (rates) {
          final editable =
              rates.where((r) => r.currencyCode != base).toList()
                ..sort((a, b) => a.currencyCode.compareTo(b.currencyCode));

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                l10n.exchangeRatesBody(base),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              _BaseRow(base: base),
              const SizedBox(height: 8),
              for (final rate in editable)
                _RateRow(
                  base: base,
                  rate: rate,
                  onEdit: () => _editRate(context, ref, base, rate),
                  onDelete: () => ref
                      .read(databaseProvider)
                      .deleteRate(rate.currencyCode),
                ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _addCurrency(context, ref, base, rates),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.exchangeRatesAddCurrency),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editRate(
    BuildContext context,
    WidgetRef ref,
    String base,
    ExchangeRate rate,
  ) async {
    final value = await _showRateDialog(
      context,
      base: base,
      currencyCode: rate.currencyCode,
      initial: rate.rateToBase,
    );
    if (value == null) return;
    await ref.read(databaseProvider).upsertRate(
          ExchangeRatesCompanion.insert(
            currencyCode: rate.currencyCode,
            rateToBase: value,
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<void> _addCurrency(
    BuildContext context,
    WidgetRef ref,
    String base,
    List<ExchangeRate> rates,
  ) async {
    final taken = {base, for (final r in rates) r.currencyCode};
    final options =
        kSupportedCurrencies.where((c) => !taken.contains(c.code)).toList();
    if (options.isEmpty) return;

    final code = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in options)
              ListTile(
                leading: Text(
                  c.symbol,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                title: Text('${c.code} · ${c.name}'),
                onTap: () => Navigator.pop(ctx, c.code),
              ),
          ],
        ),
      ),
    );
    if (code == null) return;
    if (!context.mounted) return;

    final value = await _showRateDialog(
      context,
      base: base,
      currencyCode: code,
      initial: 1.0,
    );
    if (value == null) return;
    await ref.read(databaseProvider).upsertRate(
          ExchangeRatesCompanion.insert(
            currencyCode: code,
            rateToBase: value,
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<double?> _showRateDialog(
    BuildContext context, {
    required String base,
    required String currencyCode,
    required double initial,
  }) {
    final l10n = context.l10n;
    final controller = TextEditingController(text: _trim(initial));
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$currencyCode · ${currencySymbolFor(currencyCode)}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            labelText:
                '${l10n.exchangeRatesOneBase(base)} ${currencySymbolFor(currencyCode)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              final parsed =
                  double.tryParse(controller.text.replaceAll(',', '.'));
              Navigator.pop(ctx, (parsed != null && parsed > 0) ? parsed : null);
            },
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
  }

  static String _trim(double v) {
    final s = v.toString();
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}

class _BaseRow extends StatelessWidget {
  const _BaseRow({required this.base});
  final String base;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      child: ListTile(
        title: Text(l10n.exchangeRatesBaseRow),
        subtitle: Text('1 $base = 1 $base'),
        trailing: Icon(Icons.lock_rounded, color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({
    required this.base,
    required this.rate,
    required this.onEdit,
    required this.onDelete,
  });

  final String base;
  final ExchangeRate rate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(rate.currencyCode),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      child: ListTile(
        leading: Text(
          currencySymbolFor(rate.currencyCode),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        title: Text(rate.currencyCode),
        subtitle: Text('1 $base = ${rate.rateToBase} ${rate.currencyCode}'),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
        onTap: onEdit,
      ),
    );
  }
}
