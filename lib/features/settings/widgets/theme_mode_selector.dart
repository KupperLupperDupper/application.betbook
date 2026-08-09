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

    // Labels only — with three segments on a narrow phone, an icon + label
    // makes "System" wrap mid-word. The design drops icons before labels here.
    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment(
          value: ThemeMode.system,
          label: Text(l10n.themeSystem, maxLines: 1),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          label: Text(l10n.themeLight, maxLines: 1),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text(l10n.themeDark, maxLines: 1),
        ),
      ],
      selected: {mode},
      showSelectedIcon: false,
      onSelectionChanged: (set) => notifier.setThemeMode(set.first),
    );
  }
}
