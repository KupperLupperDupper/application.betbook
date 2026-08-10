import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/routes.dart';
import '../../core/money/currency.dart';
import '../../core/utils/date_format.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/core_providers.dart';
import '../../providers/lock_providers.dart';
import '../../providers/rates_providers.dart';
import '../../providers/settings_providers.dart';
import 'widgets/set_pin_dialog.dart';
import 'widgets/settings_section.dart';
import 'widgets/theme_mode_selector.dart';

final _packageInfoProvider =
    FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());

class SettingsCard extends ConsumerWidget {
  const SettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        // ---- General ----
        SettingsSection(
          title: l10n.settingsSectionGeneral,
          children: [
            ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(l10n.settingsLanguage),
              trailing: Text(
                settings.languageCode == 'da'
                    ? l10n.languageDanish
                    : l10n.languageEnglish,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () => _pickLanguage(context, ref),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.settingsTheme,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  const ThemeModeSelector(),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.payments_rounded),
              title: Text(l10n.settingsBaseCurrency),
              trailing: Text(settings.baseCurrency,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => _pickBaseCurrency(context, ref),
            ),
          ],
        ),

        // ---- Exchange rates ----
        SettingsSection(
          title: l10n.settingsExchangeRates,
          children: [
            ListTile(
              leading: const Icon(Icons.currency_exchange_rounded),
              title: Text(l10n.exchangeRatesTitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.exchangeRates),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.autorenew_rounded),
              title: Text(l10n.ratesAutoUpdate),
              subtitle: Text(l10n.ratesAutoUpdateSubtitle),
              value: settings.ratesAutoUpdate,
              onChanged: (v) async {
                await notifier.setRatesAutoUpdate(v);
                if (v && context.mounted) await _refreshRates(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_rounded),
              title: Text(l10n.ratesRefreshNow),
              subtitle: Text(
                l10n.ratesLastUpdated(
                  settings.ratesLastFetched == null
                      ? l10n.ratesNever
                      : formatDate(settings.ratesLastFetched!,
                          settings.languageCode),
                ),
              ),
              onTap: () => _refreshRates(context, ref),
            ),
          ],
        ),

        // ---- Security ----
        SettingsSection(
          title: l10n.settingsSectionSecurity,
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.lock_outline_rounded),
              title: Text(l10n.settingsAppLock),
              subtitle: Text(l10n.settingsAppLockSubtitle),
              value: settings.appLockEnabled,
              onChanged: (v) => _toggleAppLock(context, ref, v),
            ),
            if (settings.appLockEnabled) ...[
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint_rounded),
                title: Text(l10n.settingsBiometric),
                value: settings.biometricEnabled,
                onChanged: (v) => notifier.setBiometricEnabled(v),
              ),
              ListTile(
                leading: const Icon(Icons.pin_rounded),
                title: Text(l10n.settingsChangePin),
                onTap: () async {
                  final pin = await showSetPinDialog(context);
                  if (pin != null) {
                    await ref.read(pinRepositoryProvider).setPin(pin);
                    if (context.mounted) _toast(context, l10n.toastSaved);
                  }
                },
              ),
            ],
          ],
        ),

        // ---- Data ----
        SettingsSection(
          title: l10n.settingsSectionData,
          children: [
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: Text(l10n.settingsExport),
              subtitle: Text(l10n.settingsExportSubtitle),
              onTap: () => _exportBackup(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_rounded),
              title: const Text('CSV'),
              onTap: () => _exportCsv(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: Text(l10n.settingsImport),
              subtitle: Text(l10n.settingsImportSubtitle),
              onTap: () => _importBackup(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: Text(l10n.settingsImportCsv),
              subtitle: Text(l10n.settingsImportCsvSubtitle),
              onTap: () => _importCsv(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: Text(l10n.tagsLabel),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.tags),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever_rounded,
                  color: Theme.of(context).colorScheme.error),
              title: Text(l10n.settingsClearData,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              subtitle: Text(l10n.settingsClearDataSubtitle),
              onTap: () => _clearData(context, ref),
            ),
          ],
        ),

        // ---- Responsible gambling ----
        SettingsSection(
          title: l10n.settingsSectionResponsible,
          children: [
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined),
              title: Text(l10n.rgTitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.responsibleGambling),
            ),
          ],
        ),

        // ---- About ----
        SettingsSection(
          title: l10n.settingsSectionAbout,
          children: [
            Consumer(
              builder: (context, ref, _) {
                final info = ref.watch(_packageInfoProvider);
                return ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(l10n.settingsVersion),
                  trailing: Text(
                    info.when(
                      data: (i) => '${i.version} (${i.buildNumber})',
                      loading: () => '…',
                      error: (_, _) => '—',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.settingsPrivacy),
              onTap: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.settingsPrivacy),
                  content: Text(l10n.settingsPrivacyBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.actionClose),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.settingsLicenses),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'BetBook',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = ref.read(settingsProvider).languageCode;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => RadioGroup<String>(
        groupValue: current,
        onChanged: (v) => Navigator.pop(ctx, v),
        child: SimpleDialog(
          title: Text(l10n.settingsLanguage),
          children: [
            for (final entry in {
              'en': l10n.languageEnglish,
              'da': l10n.languageDanish,
            }.entries)
              RadioListTile<String>(
                value: entry.key,
                title: Text(entry.value),
              ),
          ],
        ),
      ),
    );
    if (picked != null) ref.read(settingsProvider.notifier).setLanguage(picked);
  }

  Future<void> _pickBaseCurrency(BuildContext context, WidgetRef ref) async {
    final current = ref.read(settingsProvider).baseCurrency;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => RadioGroup<String>(
        groupValue: current,
        onChanged: (v) => Navigator.pop(ctx, v),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in kSupportedCurrencies)
              RadioListTile<String>(
                value: c.code,
                title: Text('${c.code} · ${c.name}'),
                secondary: Text(c.symbol),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked != current) {
      await ref.read(settingsProvider.notifier).setBaseCurrency(picked);
      // Base changed → refresh rates if auto-update is on.
      if (context.mounted && ref.read(settingsProvider).ratesAutoUpdate) {
        await ref.read(ratesUpdaterProvider).refreshNow();
      }
    }
  }

  Future<void> _refreshRates(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final result = await ref.read(ratesUpdaterProvider).refreshNow();
    if (!context.mounted) return;
    _toast(
      context,
      result == RatesRefreshResult.success
          ? l10n.ratesUpdated
          : l10n.ratesUpdateFailed,
    );
  }

  Future<void> _toggleAppLock(
      BuildContext context, WidgetRef ref, bool enable) async {
    final notifier = ref.read(settingsProvider.notifier);
    final pinRepo = ref.read(pinRepositoryProvider);
    if (enable) {
      final pin = await showSetPinDialog(context);
      if (pin == null) return; // cancelled
      await pinRepo.setPin(pin);
      await notifier.setAppLockEnabled(true);
    } else {
      await pinRepo.clearPin();
      await notifier.setAppLockEnabled(false);
    }
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final base = ref.read(settingsProvider).baseCurrency;
    final file =
        await ref.read(backupServiceProvider).writeBackupFile(baseCurrency: base);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'BetBook backup'),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final file = await ref.read(backupServiceProvider).writeTransactionsCsv();
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'BetBook transactions'),
    );
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    const group = XTypeGroup(label: 'BetBook backup', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsImport),
        content: Text(l10n.backupImportConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.actionConfirm)),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final content = await file.readAsString();
      await ref.read(backupServiceProvider).importFromJson(content);
      if (context.mounted) _toast(context, l10n.backupImportSuccess);
    } catch (_) {
      if (context.mounted) _toast(context, l10n.backupInvalidFile);
    }
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final base = ref.read(settingsProvider).baseCurrency;
    const group = XTypeGroup(label: 'CSV', extensions: ['csv']);
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsImportCsv),
        content: Text(l10n.csvImportConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.actionConfirm)),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final content = await file.readAsString();
      final result = await ref
          .read(backupServiceProvider)
          .importTransactionsCsv(content, baseCurrency: base);
      if (!context.mounted) return;
      final msg = result.skippedRows > 0
          ? '${l10n.csvImportAdded(result.transactionsAdded)} · '
              '${l10n.csvImportSkipped(result.skippedRows)}'
          : l10n.csvImportAdded(result.transactionsAdded);
      _toast(context, msg);
    } catch (_) {
      if (context.mounted) _toast(context, l10n.backupInvalidFile);
    }
  }

  Future<void> _clearData(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsClearData),
        content: Text(l10n.settingsClearDataConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(databaseProvider).clearAll();
      if (context.mounted) _toast(context, l10n.toastDeleted);
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
