import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/lock/lock_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/data_providers.dart';
import '../providers/lock_providers.dart';
import '../providers/notifications_providers.dart';
import '../providers/rates_providers.dart';
import '../providers/settings_providers.dart';
import '../services/notification_service.dart';
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
    NotificationService.instance.pendingRoute.addListener(_handlePendingRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Opt-in weekly FX refresh; silently no-ops when disabled or offline.
      ref.read(ratesUpdaterProvider).maybeAutoRefresh();
      // Evaluate limit warnings at launch.
      maybeFireLimitWarnings(ref);
      _handlePendingRoute();
    });
  }

  @override
  void dispose() {
    NotificationService.instance.pendingRoute
        .removeListener(_handlePendingRoute);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Navigates to the route a tapped notification requested, then clears it.
  void _handlePendingRoute() {
    final route = NotificationService.instance.pendingRoute.value;
    if (route == null || !mounted) return;
    NotificationService.instance.pendingRoute.value = null;
    ref.read(goRouterProvider).go(route);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock when the app leaves the foreground.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(lockControllerProvider.notifier).lockIfEnabled();
    }
    // Re-evaluate limit warnings whenever we come back.
    if (state == AppLifecycleState.resumed) {
      maybeFireLimitWarnings(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(goRouterProvider);
    final locked = ref.watch(lockControllerProvider);

    // Fire limit warnings when a new transaction shifts the RG status.
    ref.listen(rgStatusProvider, (_, _) => maybeFireLimitWarnings(ref));

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
