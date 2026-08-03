import 'package:flutter/foundation.dart';

import 'auth_user.dart';

/// The token pair returned by `/v1/auth/otp/verify` and `/v1/auth/refresh`.
///
/// Access tokens last 60 minutes and refresh tokens 30 days, but the client
/// never schedules around that: it refreshes reactively on a 401, which is
/// what the API documents.
@immutable
class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final AuthUser user;
  final String accessToken;
  final String refreshToken;

  /// Access-token lifetime in seconds, as reported by the server.
  final int expiresIn;

  AuthSession copyWith({
    AuthUser? user,
    String? accessToken,
    String? refreshToken,
    int? expiresIn,
  }) {
    return AuthSession(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
    );
  }

  /// Parses the `data` object shared by the verify and refresh responses.
  static AuthSession fromJson(Map<String, dynamic> data) {
    final Object? rawUser = data['user'];
    return AuthSession(
      user: AuthUser.fromJson(
        rawUser is Map<String, dynamic> ? rawUser : const <String, dynamic>{},
      ),
      accessToken: data['access_token'] as String? ?? '',
      refreshToken: data['refresh_token'] as String? ?? '',
      expiresIn: data['expires_in'] is int
          ? data['expires_in'] as int
          : int.tryParse('${data['expires_in']}') ?? 0,
    );
  }
}

/// The result of `/v1/auth/otp/request` — what the OTP screen needs to know.
@immutable
class OtpChallenge {
  const OtpChallenge({
    required this.identifier,
    required this.channel,
    required this.expiresIn,
    required this.resendAfter,
    this.debugCode,
  });

  /// Echoed back by the server; the same value must be sent to verify.
  final String identifier;

  /// `email` or `sms`.
  final String channel;

  /// Seconds the code stays valid.
  final int expiresIn;

  /// Seconds before another code may be requested. Drives the resend cooldown
  /// rather than a hard-coded number, so the client and server agree.
  final int resendAfter;

  /// Present only outside production, so the app is usable before the SMS
  /// gateway exists. Never shown in a release build.
  final String? debugCode;

  static OtpChallenge fromJson(Map<String, dynamic> data) => OtpChallenge(
        identifier: data['identifier'] as String? ?? '',
        channel: data['channel'] as String? ?? 'sms',
        expiresIn: _int(data['expires_in'], 300),
        resendAfter: _int(data['resend_after'], 60),
        debugCode: data['debug_code'] as String?,
      );

  static int _int(Object? raw, int fallback) =>
      raw is int ? raw : int.tryParse('$raw') ?? fallback;
}
