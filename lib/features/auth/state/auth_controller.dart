import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/push/device_registrar.dart';
import '../../../core/network/api_exception.dart';
import '../data/auth_failure.dart';
import '../data/auth_repository.dart';
import '../data/auth_session.dart';
import '../data/auth_user.dart';
import '../data/login_identifier.dart';
import '../data/token_store.dart';

/// Owns the customer session.
///
/// Also acts as the [TokenProvider] for [ApiClient], which is why the wiring in
/// `main.dart` builds the client first and attaches the controller afterwards —
/// the two genuinely reference each other.
///
/// Every action returns `null` on success or an [AuthFailure] on rejection, so
/// screens neither catch exceptions nor build error strings; they hand the
/// failure to `AuthFailureMessage.message(l10n)` and the text comes out in the
/// customer's language.
class AuthController extends ChangeNotifier implements TokenProvider {
  AuthController({
    required AuthRepository repository,
    required TokenStore tokenStore,
    AuthSession? initialSession,
    DeviceRegistrar? deviceRegistrar,
  })  : _repository = repository,
        _tokenStore = tokenStore,
        _session = initialSession,
        _devices = deviceRegistrar;

  /// Null in a test and in a build with no push transport, which is why every
  /// call below is null-guarded rather than the registrar being required.
  final DeviceRegistrar? _devices;

  final AuthRepository _repository;
  final TokenStore _tokenStore;

  AuthSession? _session;
  bool _isBusy = false;

  AuthUser? get user => _session?.user;

  bool get isSignedIn => _session != null;

  bool get isBusy => _isBusy;

  @override
  String? get accessToken => _session?.accessToken;

  void _setBusy(bool value) {
    if (_isBusy == value) return;
    _isBusy = value;
    notifyListeners();
  }

  /// Runs [action], mapping transport errors onto the auth vocabulary and
  /// keeping [isBusy] correct even when the call throws.
  ///
  /// A re-entrant call is refused with a failure rather than a null: null means
  /// "succeeded" to every caller, and callers navigate on success, so returning
  /// null here would push a double-submit through to the dashboard without a
  /// session. The UI already disables submit while busy, so this is defensive
  /// only.
  Future<AuthFailure?> _guard(
    Future<void> Function() action, {
    required AuthFailure onValidation,
  }) async {
    if (_isBusy) return AuthFailure.unknown;
    _setBusy(true);
    try {
      await action();
      return null;
    } on ApiException catch (error) {
      return authFailureFrom(error, validationFailure: onValidation);
    } catch (_) {
      return AuthFailure.unknown;
    } finally {
      _setBusy(false);
    }
  }

  // --- Sign-in -------------------------------------------------------------

  /// Set by [requestCode] on success; the OTP screen reads the resend cooldown
  /// and the development code from it.
  OtpChallenge? _challenge;

  OtpChallenge? get challenge => _challenge;

  Future<AuthFailure?> requestCode(LoginIdentifier identifier) {
    return _guard(
      onValidation: AuthFailure.invalidIdentifier,
      () async => _challenge = await _repository.requestCode(identifier),
    );
  }

  Future<AuthFailure?> verifyCode({
    required LoginIdentifier identifier,
    required String code,
  }) {
    return _guard(
      onValidation: AuthFailure.incorrectCode,
      () async {
        final AuthSession session = await _repository.verifyCode(
          identifier: identifier,
          code: code,
        );
        await _persist(session);
        _challenge = null;
      },
    );
  }

  Future<void> _persist(AuthSession session) async {
    _session = session;
    await _tokenStore.write(session);
    // After the token is stored, never before: registering a device is an
    // authenticated call and would 401 against a session that is not yet
    // readable. Fire-and-forget — push must not hold up a sign-in.
    unawaited(_devices?.register() ?? Future<void>.value());
  }

  // --- Session lifecycle ---------------------------------------------------

  /// Called by [ApiClient] after a 401. Returns false when there is nothing to
  /// refresh with or the server rejected the attempt.
  ///
  /// Serialisation is [ApiClient]'s job — it holds a single-flight lock, so
  /// this is never entered concurrently. Two parallel refreshes look like a
  /// stolen token to the API and sign the customer out of every device.
  @override
  Future<bool> refresh() async {
    final String? token = _session?.refreshToken;
    if (token == null || token.isEmpty) return false;
    try {
      final AuthSession refreshed = await _repository.refresh(token);
      await _persist(refreshed);
      notifyListeners();
      return true;
    } on ApiException {
      return false;
    }
  }

  @override
  Future<void> onSessionLost() async {
    if (_session == null) return;
    _session = null;
    await _tokenStore.clear();
    notifyListeners();
  }

  /// Re-fetches the profile from `GET /v1/profile` and merges it into the
  /// stored session.
  ///
  /// Deliberately does **not** go through [_guard]: `isBusy` gates the sign-in
  /// buttons app-wide, and a background profile refresh has no business
  /// disabling them. The profile screen tracks its own loading state.
  ///
  /// If the access token has expired, [ApiClient] refreshes and retries
  /// transparently; if that refresh fails it calls [onSessionLost], which
  /// clears the session here — so callers should check [isSignedIn] afterwards
  /// and send the customer back to sign-in.
  Future<AuthFailure?> loadProfile() async {
    final AuthSession? current = _session;
    if (current == null) return AuthFailure.sessionExpired;
    try {
      final AuthUser user = await _repository.profile();
      await _persist(current.copyWith(user: user));
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return authFailureFrom(error, validationFailure: AuthFailure.unknown);
    } catch (_) {
      return AuthFailure.unknown;
    }
  }

  Future<void> signOut() async {
    _challenge = null;
    // Withdraw the device first, while the token is still valid. After the
    // session is cleared this call can only 401, and an orphaned row means the
    // next rider to hold this phone gets somebody else's shift alerts.
    await _devices?.unregister();
    // Revoke server-side first, while the token is still valid; the repository
    // swallows failures so an offline sign-out still clears local state.
    await _repository.signOut();
    _session = null;
    await _tokenStore.clear();
    notifyListeners();
  }
}
