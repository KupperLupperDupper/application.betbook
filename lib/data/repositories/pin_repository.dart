import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the app-lock PIN as a salted SHA-256 hash in the platform secure
/// storage (Keystore / Keychain). The raw PIN is never persisted.
class PinRepository {
  PinRepository(this._storage);

  final FlutterSecureStorage _storage;

  static const _kHash = 'lock.pinHash';
  static const _kSalt = 'lock.pinSalt';

  Future<bool> hasPin() async => (await _storage.read(key: _kHash)) != null;

  Future<void> setPin(String pin) async {
    final salt = _randomSalt();
    await _storage.write(key: _kSalt, value: salt);
    await _storage.write(key: _kHash, value: _hash(pin, salt));
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _kSalt);
    final stored = await _storage.read(key: _kHash);
    if (salt == null || stored == null) return false;
    return _constantTimeEquals(_hash(pin, salt), stored);
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _kHash);
    await _storage.delete(key: _kSalt);
  }

  String _hash(String pin, String salt) {
    final bytes = utf8.encode('$salt::$pin');
    return sha256.convert(bytes).toString();
  }

  String _randomSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64Url.encode(bytes);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
