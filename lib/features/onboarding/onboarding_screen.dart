import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/money/currency.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/settings_providers.dart';
import '../settings/widgets/theme_mode_selector.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  static const _lastPage = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _lastPage) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _page < _lastPage ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: _page < _lastPage ? _finish : null,
                  child: Text(l10n.actionSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _WelcomeStep(),
                  _LanguageStep(),
                  _ThemeStep(),
                  _CurrencyStep(),
                ],
              ),
            ),
            _Dots(count: _lastPage + 1, index: _page),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: _next,
                child: Text(
                  _page < _lastPage ? l10n.actionNext : l10n.onboardingGetStarted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Icon(icon, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(subtitle!,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 32),
          Expanded(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _StepScaffold(
      icon: Icons.account_balance_wallet_rounded,
      title: l10n.onboardingWelcomeTitle,
      subtitle: l10n.onboardingWelcomeBody,
      child: const SizedBox.shrink(),
    );
  }
}

class _LanguageStep extends ConsumerWidget {
  const _LanguageStep();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(settingsProvider.select((s) => s.languageCode));
    return _StepScaffold(
      icon: Icons.translate_rounded,
      title: l10n.onboardingLanguageTitle,
      child: Column(
        children: [
          _OptionTile(
            label: l10n.languageEnglish,
            selected: current == 'en',
            onTap: () =>
                ref.read(settingsProvider.notifier).setLanguage('en'),
          ),
          const SizedBox(height: 12),
          _OptionTile(
            label: l10n.languageDanish,
            selected: current == 'da',
            onTap: () =>
                ref.read(settingsProvider.notifier).setLanguage('da'),
          ),
        ],
      ),
    );
  }
}

class _ThemeStep extends StatelessWidget {
  const _ThemeStep();
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _StepScaffold(
      icon: Icons.palette_rounded,
      title: l10n.onboardingThemeTitle,
      child: const ThemeModeSelector(),
    );
  }
}

class _CurrencyStep extends ConsumerWidget {
  const _CurrencyStep();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(settingsProvider.select((s) => s.baseCurrency));
    return _StepScaffold(
      icon: Icons.payments_rounded,
      title: l10n.onboardingCurrencyTitle,
      subtitle: l10n.onboardingCurrencyBody,
      child: Column(
        children: [
          for (final c in kSupportedCurrencies)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionTile(
                label: '${c.code} · ${c.name}',
                trailing: Text(c.symbol,
                    style: Theme.of(context).textTheme.titleMedium),
                selected: current == c.code,
                onTap: () =>
                    ref.read(settingsProvider.notifier).setBaseCurrency(c.code),
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.check_circle_rounded,
                      color: scheme.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
