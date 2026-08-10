import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/money/currency.dart';
import '../../core/money/money_format.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/enums.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/notifications_providers.dart';
import '../../providers/settings_providers.dart';

/// Optional safeguards: a deposit limit and a net-loss alert, reminders, and a
/// pointer to help. These are gentle nudges rather than hard blocks.
class ResponsibleGamblingScreen extends ConsumerStatefulWidget {
  const ResponsibleGamblingScreen({super.key});

  @override
  ConsumerState<ResponsibleGamblingScreen> createState() =>
      _ResponsibleGamblingScreenState();
}

class _ResponsibleGamblingScreenState
    extends ConsumerState<ResponsibleGamblingScreen> {
  /// Shown under the reminders group after a denied/blocked permission attempt.
  bool _permissionBlocked = false;

  /// Which switch the user last tried to turn on, so an "Open settings" retry
  /// can complete it once permission is granted.
  bool _pendingWeekly = false;

  Future<void> _enable(bool weekly) async {
    final notifier = ref.read(settingsProvider.notifier);
    if (weekly) {
      await notifier.setWeeklySummaryEnabled(true);
      await syncWeeklySchedule(ref);
    } else {
      await notifier.setLimitWarningsEnabled(true);
    }
  }

  /// Turning a switch ON. Routes through the rationale sheet + OS permission
  /// instead of enabling directly. See NOTIFICATIONS_HANDOFF.md §2.2.
  Future<void> _handleTurnOn(bool weekly) async {
    final settings = ref.read(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final service = ref.read(notificationServiceProvider);
    _pendingWeekly = weekly;

    if (!settings.notifRationaleShown) {
      // First time: explain before touching the OS dialog.
      final proceed = await _showRationaleSheet();
      await notifier.markNotifRationaleShown();
      if (proceed != true) return; // "Not now" — leave the toggle off.
      final granted = await service.requestPermission();
      if (!mounted) return;
      if (granted) {
        await _enable(weekly);
        if (!mounted) return;
        setState(() => _permissionBlocked = false);
      } else {
        setState(() => _permissionBlocked = true);
      }
      return;
    }

    // Rationale already shown: the OS dialog / blocked state is the whole flow.
    final enabled = await service.areEnabled();
    if (!mounted) return;
    if (enabled) {
      await _enable(weekly);
      if (!mounted) return;
      setState(() => _permissionBlocked = false);
      return;
    }
    // Re-request acts as a lightweight "open settings" (re-prompts or no-ops).
    final granted = await service.requestPermission();
    if (!mounted) return;
    if (granted) {
      await _enable(weekly);
      if (!mounted) return;
      setState(() => _permissionBlocked = false);
    } else {
      setState(() => _permissionBlocked = true);
    }
  }

  Future<void> _handleTurnOff(bool weekly) async {
    final notifier = ref.read(settingsProvider.notifier);
    if (weekly) {
      await notifier.setWeeklySummaryEnabled(false);
      await syncWeeklySchedule(ref);
    } else {
      await notifier.setLimitWarningsEnabled(false);
    }
    if (!mounted) return;
    setState(() => _permissionBlocked = false);
  }

  /// The "Open settings" retry: re-request permission and, if granted, finish
  /// enabling the switch the user was trying to turn on. Never a dead toggle.
  Future<void> _retryFromBlocked() async {
    final service = ref.read(notificationServiceProvider);
    final granted = await service.requestPermission();
    if (!mounted) return;
    if (granted) {
      await _enable(_pendingWeekly);
      if (!mounted) return;
      setState(() => _permissionBlocked = false);
    }
  }

  Future<bool?> _showRationaleSheet() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_none_rounded,
                    size: 40, color: scheme.primary),
                const SizedBox(height: 16),
                Text(l10n.notifRationaleTitle,
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(l10n.notifRationaleBody,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      child: Text(l10n.notNow),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      child: Text(l10n.continueLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final baseSymbol = currencySymbolFor(settings.baseCurrency);
    final limitsConfigured =
        settings.depositLimitEnabled || settings.netLossAlertEnabled;

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
                              label: Text(l10n.rgPeriodDaily,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            ButtonSegment(
                              value: LimitPeriod.weekly,
                              label: Text(l10n.rgPeriodWeekly,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            ButtonSegment(
                              value: LimitPeriod.monthly,
                              label: Text(l10n.rgPeriodMonthly,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
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

          // Reminders -----------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(
              l10n.reminders.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.weeklySummary),
                  subtitle: Text(l10n.weeklySummarySub),
                  value: settings.weeklySummaryEnabled,
                  onChanged: (v) =>
                      v ? _handleTurnOn(true) : _handleTurnOff(true),
                ),
                SwitchListTile(
                  title: Text(l10n.limitWarnings),
                  subtitle: Text(
                    limitsConfigured ? l10n.limitWarningsSub : l10n.setLimitFirst,
                  ),
                  value: settings.limitWarningsEnabled,
                  onChanged: limitsConfigured
                      ? (v) => v ? _handleTurnOn(false) : _handleTurnOff(false)
                      : null,
                ),
                if (_permissionBlocked)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.notifDisabledSystem,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                        TextButton(
                          onPressed: _retryFromBlocked,
                          child: Text(l10n.openSettings),
                        ),
                      ],
                    ),
                  ),
                ListTile(
                  title: Text(l10n.takeABreak),
                  subtitle: Text(l10n.takeABreakSub),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(Routes.takeABreak),
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
