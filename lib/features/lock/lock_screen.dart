import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/lock_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/suit_marks.dart';
import 'widgets/pin_pad.dart';

/// Full-screen overlay shown while the app is locked. Opaque so it fully
/// covers the app, and non-dismissible via the system back gesture.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  static const _pinLength = 4;
  String? _errorText;
  bool _authenticating = false;

  // Drives the biometric-success dot animation.
  bool _success = false;
  int _successFill = 0;

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

  /// Fills the PIN dots one-by-one in the success colour, then unlocks — a
  /// small confirmation that the biometric check passed.
  Future<void> _playSuccessThenUnlock() async {
    if (!mounted) return;
    setState(() => _success = true);
    HapticFeedback.selectionClick();
    for (var i = 1; i <= _pinLength; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 85));
      if (!mounted) return;
      setState(() => _successFill = i);
    }
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 260));
    _unlock();
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
        await _playSuccessThenUnlock();
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
                  const BrandMark(size: 64),
                  const SizedBox(height: 24),
                  Text(
                    l10n.lockTitle,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.lockInstruction,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  if (ref.watch(
                      settingsProvider.select((s) => s.biometricEnabled))) ...[
                    const SizedBox(height: 28),
                    Semantics(
                      button: true,
                      label: l10n.lockUseBiometrics,
                      child: InkWell(
                        onTap:
                            _authenticating ? null : _authenticateBiometric,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fingerprint_rounded,
                            size: 38,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  PinPad(
                    length: _pinLength,
                    errorText: _errorText,
                    onCompleted: _onPinCompleted,
                    success: _success,
                    overrideFilled: _success ? _successFill : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
