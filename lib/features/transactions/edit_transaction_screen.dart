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
import '../../widgets/undo_snackbar.dart';

/// Full-screen route for creating or editing a transaction. The amount is
/// entered exclusively through a custom on-screen keypad — the OS keyboard is
/// never summoned for it (only the optional note uses the system keyboard).
class EditTransactionScreen extends ConsumerStatefulWidget {
  const EditTransactionScreen({
    super.key,
    this.transactionId,
    this.initialSiteId,
    this.initialType,
    this.initialRawAmount,
  });

  final String? transactionId;
  final String? initialSiteId;

  /// Prefill for the "More fields" hand-off from quick-add.
  final TransactionType? initialType;
  final String? initialRawAmount;

  bool get isEditing => transactionId != null;

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState
    extends ConsumerState<EditTransactionScreen> {
  final _noteController = TextEditingController();

  /// Canonical raw amount: digits with an optional single `.` separator,
  /// e.g. `"500"`, `"12.5"`, `"12."`. Never touched by a controller.
  String _raw = '';

  TransactionType _type = TransactionType.deposit;
  String? _siteId;
  DateTime _date = DateTime.now();
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _siteId = widget.initialSiteId;
    if (widget.initialType != null) _type = widget.initialType!;
    if (widget.initialRawAmount != null && widget.initialRawAmount!.isNotEmpty) {
      _raw = widget.initialRawAmount!;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ── Amount model ─────────────────────────────────────────────────────────

  /// The parsed value, or null when empty / not a number.
  double? get _amountValue => AmountInput.value(_raw);

  bool get _canSave {
    final v = _amountValue;
    return v != null && v > 0 && _siteId != null && !_saving;
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    final next = AmountInput.nextRaw(_raw, key);
    if (next == _raw) return;
    setState(() => _raw = next);
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted) return;
    setState(() {
      _date = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _date.hour,
        time?.minute ?? _date.minute,
      );
    });
  }

  Future<void> _openSiteSheet(List<Site> sites) async {
    final l10n = context.l10n;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.add_rounded),
                title: Text(l10n.siteAdd),
                onTap: () {
                  sheetContext.pop();
                  context.push(Routes.newSite);
                },
              ),
              const Divider(height: 1),
              for (final site in sites)
                ListTile(
                  leading: _SiteAvatar(site: site),
                  title: Text(site.name),
                  trailing: site.id == _siteId
                      ? Icon(
                          Icons.check_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => sheetContext.pop(site.id),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _siteId = selected);
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.txDelete),
        content: Text(l10n.txDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => dialogContext.pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(transactionRepositoryProvider);
    final tx = await repo.getById(widget.transactionId!);
    await repo.deleteTransaction(widget.transactionId!);
    if (mounted) context.pop();
    if (tx != null) {
      showUndoSnackBar(
        messenger,
        message: l10n.txDeletedSnack,
        undoLabel: l10n.actionUndo,
        onUndo: () => repo.restore(tx),
      );
    }
  }

  Future<void> _save() async {
    final value = _amountValue;
    if (value == null || value <= 0 || _siteId == null) return;
    setState(() => _saving = true);
    final minor = majorToMinor(value);
    final note = _noteController.text.trim();
    final repo = ref.read(transactionRepositoryProvider);
    if (widget.isEditing) {
      await repo.updateTransaction(
        id: widget.transactionId!,
        siteId: _siteId!,
        type: _type,
        amountMinor: minor,
        date: _date,
        note: note.isEmpty ? null : note,
      );
    } else {
      await repo.createTransaction(
        siteId: _siteId!,
        type: _type,
        amountMinor: minor,
        date: _date,
        note: note.isEmpty ? null : note,
      );
    }
    if (mounted) context.pop();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = ref.watch(settingsProvider.select((s) => s.languageCode));
    final sites = ref.watch(sitesProvider).valueOrNull ?? const <Site>[];

    // Prefill once when editing an existing transaction.
    if (widget.isEditing && !_initialized) {
      final tx = ref
          .watch(allTransactionsProvider)
          .valueOrNull
          ?.where((t) => t.id == widget.transactionId)
          .firstOrNull;
      if (tx != null) {
        _type = tx.type;
        _siteId = tx.siteId;
        _date = tx.date;
        _raw = AmountInput.rawFromMajor(minorToMajor(tx.amountMinor));
        _noteController.text = tx.note ?? '';
        _initialized = true;
      }
    }

    if (sites.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.txAdd),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.txSelectSite, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  context.pop();
                  context.push(Routes.newSite);
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.siteAdd),
              ),
            ],
          ),
        ),
      );
    }

    // Ensure a valid selected site so the display always has a currency.
    _siteId ??= sites.first.id;

    final site = sites.firstWhere(
      (s) => s.id == _siteId,
      orElse: () => sites.first,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.isEditing ? l10n.txEdit : l10n.txAdd),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: [
                    _typeToggle(l10n),
                    const SizedBox(height: 24),
                    _amountDisplay(l10n, locale, site),
                    const SizedBox(height: 24),
                    _siteSelector(l10n, site, sites),
                    const SizedBox(height: 12),
                    _dateRow(l10n, locale),
                    const SizedBox(height: 12),
                    _noteField(l10n),
                  ],
                ),
              ),
            ),
            AmountKeypad(
              decimalSeparator: AmountInput.decimalSeparator(locale),
              onTap: _onKeyTap,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canSave ? _save : null,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.txSaveTransaction),
                ),
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
      height: 48,
      child: SegmentedButton<TransactionType>(
        segments: [
          ButtonSegment(
            value: TransactionType.deposit,
            label: Text(l10n.txTypeDeposit,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            icon: const Icon(Icons.arrow_downward_rounded),
          ),
          ButtonSegment(
            value: TransactionType.withdrawal,
            label: Text(l10n.txTypeWithdrawal,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
        selected: {_type},
        onSelectionChanged: (s) => setState(() => _type = s.first),
      ),
    );
  }

  Widget _amountDisplay(AppLocalizations l10n, String locale, Site site) {
    final theme = Theme.of(context);
    final value = _amountValue;
    final isValid = value != null && value > 0;
    final numberColor = isValid
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Column(
        children: [
          Text(
            l10n.txAmount.toUpperCase(),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
            ),
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  AmountInput.display(_raw, locale),
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: numberColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  currencySymbolFor(site.currencyCode),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _siteSelector(AppLocalizations l10n, Site site, List<Site> sites) {
    final theme = Theme.of(context);
    return _BorderedRow(
      onTap: () => _openSiteSheet(sites),
      child: Row(
        children: [
          _SiteAvatar(site: site),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.txSite,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  site.name,
                  style: theme.textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.expand_more_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _dateRow(AppLocalizations l10n, String locale) {
    final theme = Theme.of(context);
    return _BorderedRow(
      onTap: _pickDateTime,
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.txDate,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          Text(
            DateFormat('d MMM yyyy · HH:mm', locale).format(_date),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteField(AppLocalizations l10n) {
    return TextFormField(
      controller: _noteController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: l10n.txNote,
        hintText: l10n.txNoteHint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// A small colored rounded-square avatar showing the site's initial in white.
class _SiteAvatar extends StatelessWidget {
  const _SiteAvatar({required this.site});

  final Site site;

  @override
  Widget build(BuildContext context) {
    final initial =
        site.name.isNotEmpty ? site.name.characters.first.toUpperCase() : '?';
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color(site.colorValue),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// An outlined, tappable row used for the site and date selectors.
class _BorderedRow extends StatelessWidget {
  const _BorderedRow({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}

