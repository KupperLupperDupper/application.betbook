import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../data/repositories/pin_repository.dart';
import 'settings_providers.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final pinRepositoryProvider = Provider<PinRepository>(
  (ref) => PinRepository(ref.watch(secureStorageProvider)),
);

final localAuthProvider = Provider<LocalAuthentication>(
  (ref) => LocalAuthentication(),
);

/// Whether the app is currently locked behind the lock screen.
///
/// Initial value follows the app-lock setting: locked on launch when enabled.
class LockController extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(settingsProvider.select((s) => s.appLockEnabled));
  }

  void unlock() => state = false;

  /// Re-locks when the app returns from background (if the lock is enabled).
  void lockIfEnabled() {
    if (ref.read(settingsProvider).appLockEnabled) state = true;
  }
}

final lockControllerProvider =
    NotifierProvider<LockController, bool>(LockController.new);
