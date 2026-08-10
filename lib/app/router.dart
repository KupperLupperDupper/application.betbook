import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/enums.dart';
import '../features/home/home_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/exchange_rates_screen.dart';
import '../features/settings/responsible_gambling_screen.dart';
import '../features/sites/edit_site_screen.dart';
import '../features/sites/site_detail_screen.dart';
import '../features/transactions/edit_transaction_screen.dart';
import '../providers/settings_providers.dart';
import 'routes.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    redirect: (context, state) {
      final onboarded = ref.read(settingsProvider).onboardingComplete;
      final atOnboarding = state.matchedLocation == Routes.onboarding;

      if (!onboarded && !atOnboarding) return Routes.onboarding;
      if (onboarded && atOnboarding) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, _) => const HomeShell(),
      ),
      GoRoute(
        path: Routes.newSite,
        builder: (_, _) => const EditSiteScreen(),
      ),
      GoRoute(
        path: Routes.editSitePath,
        builder: (_, state) =>
            EditSiteScreen(siteId: state.pathParameters['id']),
      ),
      GoRoute(
        path: Routes.siteDetailPath,
        builder: (_, state) =>
            SiteDetailScreen(siteId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.newTransaction,
        builder: (_, state) {
          final typeName = state.uri.queryParameters['type'];
          return EditTransactionScreen(
            initialSiteId: state.uri.queryParameters['siteId'],
            initialType: typeName == null
                ? null
                : TransactionType.values
                    .where((t) => t.name == typeName)
                    .firstOrNull,
            initialRawAmount: state.uri.queryParameters['amount'],
          );
        },
      ),
      GoRoute(
        path: Routes.editTransactionPath,
        builder: (_, state) =>
            EditTransactionScreen(transactionId: state.pathParameters['id']),
      ),
      GoRoute(
        path: Routes.exchangeRates,
        builder: (_, _) => const ExchangeRatesScreen(),
      ),
      GoRoute(
        path: Routes.responsibleGambling,
        builder: (_, _) => const ResponsibleGamblingScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});
