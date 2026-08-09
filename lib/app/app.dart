import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/lock/lock_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/lock_providers.dart';
import '../providers/rates_providers.dart';
import '../providers/settings_providers.dart';
import 'router.dart';

class BetBookApp extends ConsumerStatefulWidget {
  const BetBookApp({super.key});

  @override
  ConsumerState<BetBookApp> createState() => _BetBookAppState();
}

class _BetBookAppState extends ConsumerState<BetBookApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Opt-in weekly FX refresh; silently no-ops when disabled or offline.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ratesUpdaterProvider).maybeAutoRefresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock when the app leaves the foreground.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(lockControllerProvider.notifier).lockIfEnabled();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(goRouterProvider);
    final locked = ref.watch(lockControllerProvider);

    return MaterialApp.router(
      title: 'BetBook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (locked)
              const RepaintBoundary(child: LockScreen()),
          ],
        );
      },
    );
  }
}
