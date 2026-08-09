import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/money/currency.dart';
import '../../core/money/money_format.dart';
import '../../core/utils/date_format.dart';
import '../../data/models/enums.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_providers.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  const EditTransactionScreen({
    super.key,
    this.transactionId,
    this.initialSiteId,
  });

  final String? transactionId;
  final String? initialSiteId;

  bool get isEditing => transactionId != null;

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState
    extends ConsumerState<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.deposit;
  String? _siteId;
  DateTime _date = DateTime.now();
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _siteId = widget.initialSiteId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? _parseAmountMinor() {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) return null;
    return majorToMinor(value);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date =
          DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_siteId == null) return;
    final minor = _parseAmountMinor()!;
    setState(() => _saving = true);
    final repo = ref.read(transactionRepositoryProvider);
    if (widget.isEditing) {
      await repo.updateTransaction(
        id: widget.transactionId!,
        siteId: _siteId!,
        type: _type,
        amountMinor: minor,
        date: _date,
        note: _noteController.text,
      );
    } else {
      await repo.createTransaction(
        siteId: _siteId!,
        type: _type,
        amountMinor: minor,
        date: _date,
        note: _noteController.text,
      );
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = ref.watch(settingsProvider.select((s) => s.languageCode));
    final sites = ref.watch(sitesProvider).valueOrNull ?? const [];

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
        _amountController.text = minorToMajor(tx.amountMinor).toString();
        _noteController.text = tx.note ?? '';
        _initialized = true;
      }
    }

    if (sites.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.txAdd)),
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

    // Ensure a valid selected site.
    _siteId ??= sites.first.id;
    final selectedSite = sites.firstWhere(
      (s) => s.id == _siteId,
      orElse: () => sites.first,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? l10n.txEdit : l10n.txAdd)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(
                  value: TransactionType.deposit,
                  label: Text(l10n.txTypeDeposit),
                  icon: const Icon(Icons.south_west_rounded),
                ),
                ButtonSegment(
                  value: TransactionType.withdrawal,
                  label: Text(l10n.txTypeWithdrawal),
                  icon: const Icon(Icons.north_east_rounded),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountController,
              autofocus: !widget.isEditing,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: l10n.txAmount,
                prefixText: '${currencySymbolFor(selectedSite.currencyCode)} ',
              ),
              validator: (_) =>
                  _parseAmountMinor() == null ? l10n.txAmountError : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _siteId,
              decoration: InputDecoration(labelText: l10n.txSite),
              items: [
                for (final s in sites)
                  DropdownMenuItem(
                    value: s.id,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(s.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(s.name),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _siteId = v),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: _pickDate,
              leading: const Icon(Icons.calendar_today_rounded),
              title: Text(l10n.txDate),
              trailing: Text(
                formatDate(_date, locale),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.txNote,
                hintText: l10n.txNoteHint,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}
