import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/lock_providers.dart';
import '../../providers/settings_providers.dart';
import 'widgets/pin_pad.dart';

/// Full-screen overlay shown while the app is locked. Opaque so it fully
/// covers the app, and non-dismissible via the system back gesture.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String? _errorText;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onStart());
  }

  Future<void> _onStart() async {
    final hasPin = await ref.read(pinRepositoryProvider).hasPin();
    final biometric = ref.read(settingsProvider).biometricEnabled;

    // Nothing to check against: unlock straight away.
    if (!hasPin && !biometric) {
      _unlock();
      return;
    }

    if (biometric) await _authenticateBiometric();
  }

  void _unlock() {
    if (!mounted) return;
    ref.read(lockControllerProvider.notifier).unlock();
  }

  Future<void> _authenticateBiometric() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final l10n = context.l10n;
    try {
      final auth = ref.read(localAuthProvider);
      final ok = await auth.authenticate(
        localizedReason: l10n.lockUnlock,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (ok) {
        _unlock();
        return;
      }
    } catch (_) {
      // Biometric unavailable or cancelled: fall back to PIN entry.
    }
    if (mounted) setState(() => _authenticating = false);
  }

  Future<void> _onPinCompleted(String pin) async {
    final l10n = context.l10n;
    final ok = await ref.read(pinRepositoryProvider).verifyPin(pin);
    if (ok) {
      _unlock();
      return;
    }
    HapticFeedback.heavyImpact();
    if (mounted) setState(() => _errorText = l10n.lockWrongPin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 48,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'BetBook',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.lockTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 40),
                  PinPad(
                    title: l10n.lockEnterPin,
                    errorText: _errorText,
                    onCompleted: _onPinCompleted,
                  ),
                  if (ref.watch(
                      settingsProvider.select((s) => s.biometricEnabled))) ...[
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: _authenticating ? null : _authenticateBiometric,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: Text(l10n.lockUseBiometrics),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
