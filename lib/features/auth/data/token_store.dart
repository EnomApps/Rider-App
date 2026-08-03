import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_session.dart';
import 'auth_user.dart';

/// Persists the session across launches.
///
/// Tokens go to the platform keystore — Keychain on iOS, EncryptedSharedPrefs
/// on Android — because a refresh token is a 30-day credential and
/// SharedPreferences is readable on a rooted or jailbroken device. The user
/// profile rides along in the same store for simplicity.
abstract class TokenStore {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const String _accessKey = 'nexmile.access_token';
  static const String _refreshKey = 'nexmile.refresh_token';
  static const String _userKey = 'nexmile.user';
  static const String _expiresKey = 'nexmile.expires_in';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    try {
      final String? access = await _storage.read(key: _accessKey);
      final String? refresh = await _storage.read(key: _refreshKey);
      final AuthUser? user = AuthUser.decode(await _storage.read(key: _userKey));

      if (access == null || refresh == null || user == null) return null;

      return AuthSession(
        user: user,
        accessToken: access,
        refreshToken: refresh,
        expiresIn:
            int.tryParse(await _storage.read(key: _expiresKey) ?? '') ?? 0,
      );
    } catch (_) {
      // A keystore that cannot be read (corrupt entry, key rotation after a
      // restore-from-backup) must not stop the app from starting. Treat it as
      // signed out.
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) async {
    await _storage.write(key: _accessKey, value: session.accessToken);
    await _storage.write(key: _refreshKey, value: session.refreshToken);
    await _storage.write(key: _userKey, value: session.user.encode());
    await _storage.write(key: _expiresKey, value: '${session.expiresIn}');
  }

  @override
  Future<void> clear() async {
    try {
      await Future.wait(<Future<void>>[
        _storage.delete(key: _accessKey),
        _storage.delete(key: _refreshKey),
        _storage.delete(key: _userKey),
        _storage.delete(key: _expiresKey),
      ]);
    } catch (_) {
      // Nothing useful to do if the keystore itself is unavailable.
    }
  }
}

/// In-memory store used by tests and by any build that should not touch the
/// platform keystore.
class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore([this._session]);

  AuthSession? _session;

  @override
  Future<AuthSession?> read() async => _session;

  @override
  Future<void> write(AuthSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
