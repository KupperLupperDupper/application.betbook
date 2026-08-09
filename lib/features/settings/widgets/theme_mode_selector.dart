import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/settings_providers.dart';

/// Segmented system / light / dark picker bound to [settingsProvider].
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final notifier = ref.read(settingsProvider.notifier);

    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment(
          value: ThemeMode.system,
          label: Text(l10n.themeSystem),
          icon: const Icon(Icons.brightness_auto_rounded),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          label: Text(l10n.themeLight),
          icon: const Icon(Icons.light_mode_rounded),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text(l10n.themeDark),
          icon: const Icon(Icons.dark_mode_rounded),
        ),
      ],
      selected: {mode},
      showSelectedIcon: false,
      onSelectionChanged: (set) => notifier.setThemeMode(set.first),
    );
  }
}
