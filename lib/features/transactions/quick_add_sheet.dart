import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/money/amount_input.dart';
import '../../core/money/currency.dart';
import '../../core/money/money_format.dart';
import '../../data/database/database.dart';
import '../../data/models/enums.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/amount_keypad.dart';
import '../../widgets/mini_card_avatar.dart';
import '../../widgets/undo_snackbar.dart';

/// Opens the quick-add sheet — a lightweight accelerator over the full editor
/// (QUICKADD_HANDOFF §2). Records a movement that already happened; never
/// suggests a new one.
Future<void> showQuickAddSheet(
  BuildContext context, {
  String? initialSiteId,
  TransactionType? initialType,
  String? initialRawAmount,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _QuickAddSheet(
      initialSiteId: initialSiteId,
      initialType: initialType,
      initialRawAmount: initialRawAmount,
    ),
  );
}

class _QuickAddSheet extends ConsumerStatefulWidget {
  const _QuickAddSheet({
    this.initialSiteId,
    this.initialType,
    this.initialRawAmount,
  });
  final String? initialSiteId;
  final TransactionType? initialType;
  final String? initialRawAmount;

  @override
  ConsumerState<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<_QuickAddSheet> {
  String _raw = '';
  TransactionType _type = TransactionType.deposit;
  String? _siteId;
  bool _siteInitialised = false;
  bool _saving = false;
  bool _showAmountError = false;
  bool _showSiteError = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) _type = widget.initialType!;
    if (widget.initialRawAmount != null) _raw = widget.initialRawAmount!;
  }

  double? get _amountValue => AmountInput.value(_raw);
  bool get _canSave {
    final v = _amountValue;
    return v != null && v > 0 && _siteId != null && !_saving;
  }

  void _onKey(String key) {
    HapticFeedback.lightImpact();
    final next = AmountInput.nextRaw(_raw, key);
    if (next == _raw) return;
    setState(() {
      _raw = next;
      _showAmountError = false;
    });
  }

  /// The 3 most recent *distinct* amounts for the selected site + type, newest
  /// first — recall, never suggestion. Hidden below 2 distinct values.
  List<int> _recentAmounts(List<Transaction> txs) {
    if (_siteId == null) return const [];
    final seen = <int>{};
    final out = <int>[];
    for (final t in txs) {
      if (t.siteId != _siteId || t.type != _type) continue;
      if (seen.add(t.amountMinor)) out.add(t.amountMinor);
      if (out.length == 3) break;
    }
    return out.length >= 2 ? out : const [];
  }

  Future<void> _pickSite(List<Site> sites) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CompactSitePicker(sites: sites, selectedId: _siteId),
    );
    if (selected != null && mounted) {
      setState(() {
        _siteId = selected;
        _showSiteError = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_canSave) {
      setState(() {
        _showAmountError = _amountValue == null || _amountValue! <= 0;
        _showSiteError = _siteId == null;
      });
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final repo = ref.read(transactionRepositoryProvider);
    final id = await repo.createTransaction(
      siteId: _siteId!,
      type: _type,
      amountMinor: majorToMinor(_amountValue!),
      date: DateTime.now(),
    );
    if (mounted) Navigator.of(context).pop();
    showUndoSnackBar(
      messenger,
      message: l10n.quickAddSaved,
      undoLabel: l10n.actionUndo,
      onUndo: () => repo.deleteTransaction(id),
    );
  }

  void _openFullEditor() {
    final params = <String, String>{'type': _type.name};
    if (_siteId != null) params['siteId'] = _siteId!;
    if (_raw.isNotEmpty) params['amount'] = _raw;
    final uri = Uri(path: Routes.newTransaction, queryParameters: params);
    Navigator.of(context).pop();
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = ref.watch(settingsProvider.select((s) => s.languageCode));
    final sites = ref.watch(sitesProvider).valueOrNull ?? const <Site>[];
    final txs = ref.watch(allTransactionsProvider).valueOrNull ?? const [];

    // Default site: the one passed in, else the last-used site (most recent
    // transaction), else nothing (QUICKADD_HANDOFF §1.4).
    if (!_siteInitialised) {
      _siteInitialised = true;
      _siteId = widget.initialSiteId ??
          (txs.isNotEmpty ? txs.first.siteId : null);
      if (_siteId != null && !sites.any((s) => s.id == _siteId)) {
        _siteId = null; // last-used site was deleted
      }
    }

    final site = _siteId == null
        ? null
        : sites.where((s) => s.id == _siteId).firstOrNull;
    final recents = _recentAmounts(txs);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Text(l10n.quickAddTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  children: [
                    _typeToggle(l10n),
                    const SizedBox(height: 20),
                    _amountDisplay(theme, locale, site),
                    if (_showAmountError) ...[
                      const SizedBox(height: 8),
                      _errorLine(theme, l10n.quickAddEnterAmount),
                    ],
                    if (recents.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _recentChips(theme, recents, site, locale),
                    ],
                    const SizedBox(height: 20),
                    _siteRow(theme, l10n, site),
                    if (_showSiteError) ...[
                      const SizedBox(height: 8),
                      _errorLine(theme, l10n.quickAddSelectSite),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      l10n.quickAddDatedNow(DateFormat.Hm(locale).format(
                        DateTime.now(),
                      )),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            AmountKeypad(
              decimalSeparator: AmountInput.decimalSeparator(locale),
              onTap: _onKey,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _openFullEditor,
                    child: Text(l10n.quickAddMoreFields),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _canSave
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: _canSave
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.actionSave),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeToggle(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: SegmentedButton<TransactionType>(
        segments: [
          ButtonSegment(
            value: TransactionType.deposit,
            label: Text(l10n.txTypeDeposit,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ButtonSegment(
            value: TransactionType.withdrawal,
            label: Text(l10n.txTypeWithdrawal,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
        selected: {_type},
        onSelectionChanged: (s) => setState(() {
          _type = s.first;
          _showAmountError = false;
        }),
      ),
    );
  }

  Widget _amountDisplay(ThemeData theme, String locale, Site? site) {
    final isValid = (_amountValue ?? 0) > 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          AmountInput.display(_raw, locale),
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w800,
            color: isValid
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.38),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          currencySymbolFor(site?.currencyCode ?? ''),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _recentChips(
      ThemeData theme, List<int> recents, Site? site, String locale) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.recentAmounts.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final minor in recents)
                ActionChip(
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  side: BorderSide.none,
                  label: Text(
                    formatMinorPlain(minor, localeName: locale),
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  onPressed: () => setState(() {
                    _raw =
                        AmountInput.rawFromMajor(minorToMajor(minor));
                    _showAmountError = false;
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _siteRow(ThemeData theme, AppLocalizations l10n, Site? site) {
    return InkWell(
      onTap: () =>
          _pickSite(ref.read(sitesProvider).valueOrNull ?? const <Site>[]),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (site != null)
              MiniCardAvatar(
                siteId: site.id,
                name: site.name,
                colorValue: site.colorValue,
              )
            else
              _dashedAvatarSlot(theme),
            const SizedBox(width: 12),
            Expanded(
              child: site != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(site.name,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          site.currencyCode,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      l10n.quickAddChooseSite,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
            Icon(Icons.unfold_more_rounded,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _dashedAvatarSlot(ThemeData theme) {
    return Container(
      width: 32,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
    );
  }

  Widget _errorLine(ThemeData theme, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

/// A compact site picker nested inside quick-add (QUICKADD_HANDOFF §2.3).
class _CompactSitePicker extends StatelessWidget {
  const _CompactSitePicker({required this.sites, required this.selectedId});

  final List<Site> sites;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final site in sites)
              ListTile(
                leading: MiniCardAvatar(
                  siteId: site.id,
                  name: site.name,
                  colorValue: site.colorValue,
                ),
                title: Text(site.name),
                subtitle: Text(site.currencyCode),
                trailing: site.id == selectedId
                    ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(site.id),
              ),
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: Text(context.l10n.quickAddNewSite),
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.newSite);
              },
            ),
          ],
        ),
      ),
    );
  }
}
