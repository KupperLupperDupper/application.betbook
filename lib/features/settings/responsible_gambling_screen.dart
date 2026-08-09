import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money/currency.dart';
import '../../core/money/money_format.dart';
import '../../data/models/enums.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/settings_providers.dart';

/// Optional safeguards: a deposit limit and a net-loss alert, plus a pointer to
/// help. These are gentle nudges rather than hard blocks.
class ResponsibleGamblingScreen extends ConsumerWidget {
  const ResponsibleGamblingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final baseSymbol = currencySymbolFor(settings.baseCurrency);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rgTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.rgIntro,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Deposit limit -------------------------------------------------
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.rgDepositLimit),
                  subtitle: Text(l10n.rgDepositLimitSubtitle),
                  value: settings.depositLimitEnabled,
                  onChanged: (v) {
                    if (v) {
                      notifier.setDepositLimit(
                        enabled: true,
                        amountMinor: settings.depositLimitMinor,
                        period: settings.depositLimitPeriod,
                      );
                    } else {
                      notifier.setDepositLimit(enabled: false);
                    }
                  },
                ),
                if (settings.depositLimitEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AmountField(
                          key: ValueKey('deposit-${settings.depositLimitMinor}'),
                          label: l10n.rgLimitAmount,
                          prefix: baseSymbol,
                          initial: minorToMajor(settings.depositLimitMinor),
                          onSaved: (v) => notifier.setDepositLimit(
                            enabled: true,
                            amountMinor: majorToMinor(v),
                            period: settings.depositLimitPeriod,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<LimitPeriod>(
                          segments: [
                            ButtonSegment(
                              value: LimitPeriod.daily,
                              label: Text(l10n.rgPeriodDaily),
                            ),
                            ButtonSegment(
                              value: LimitPeriod.weekly,
                              label: Text(l10n.rgPeriodWeekly),
                            ),
                            ButtonSegment(
                              value: LimitPeriod.monthly,
                              label: Text(l10n.rgPeriodMonthly),
                            ),
                          ],
                          selected: {settings.depositLimitPeriod},
                          onSelectionChanged: (sel) => notifier.setDepositLimit(
                            enabled: true,
                            amountMinor: settings.depositLimitMinor,
                            period: sel.first,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Net-loss alert ------------------------------------------------
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.rgNetLossAlert),
                  subtitle: Text(l10n.rgNetLossAlertSubtitle),
                  value: settings.netLossAlertEnabled,
                  onChanged: (v) {
                    if (v) {
                      notifier.setNetLossAlert(
                        enabled: true,
                        amountMinor: settings.netLossAlertMinor,
                      );
                    } else {
                      notifier.setNetLossAlert(enabled: false);
                    }
                  },
                ),
                if (settings.netLossAlertEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _AmountField(
                      key: ValueKey('netloss-${settings.netLossAlertMinor}'),
                      label: l10n.rgLimitAmount,
                      prefix: baseSymbol,
                      initial: minorToMajor(settings.netLossAlertMinor),
                      onSaved: (v) => notifier.setNetLossAlert(
                        enabled: true,
                        amountMinor: majorToMinor(v),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Help ----------------------------------------------------------
          Card(
            elevation: 0,
            color: scheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.phone_rounded, color: scheme.onSecondaryContainer),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.rgHelpTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.rgHelpBody,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A decimal amount field that persists on submit or when it loses focus,
/// rather than on every keystroke.
class _AmountField extends StatefulWidget {
  const _AmountField({
    super.key,
    required this.label,
    required this.prefix,
    required this.initial,
    required this.onSaved,
  });

  final String label;
  final String prefix;
  final double initial;
  final void Function(double value) onSaved;

  @override
  State<_AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<_AmountField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.initial));
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _save();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (parsed != null && parsed >= 0) widget.onSaved(parsed);
  }

  static String _format(double v) {
    final s = v.toString();
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        prefixText: '${widget.prefix} ',
      ),
      onSubmitted: (_) => _save(),
    );
  }
}
