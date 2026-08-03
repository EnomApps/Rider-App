import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Debug-only wire log for [ApiClient].
///
/// Every request and response is printed to the console so a failing call can
/// be diagnosed from `flutter run` without a proxy. Three rules make that safe
/// and useful:
///
/// **1. Never in a release build.** Every method is a no-op unless
/// [kDebugMode] is set, and the calls are additionally wrapped in `assert`
/// blocks at the call sites, so the string interpolation does not even run in
/// release. Android's logcat is readable by `adb` from any machine a rider
/// plugs their phone into.
///
/// **2. Secrets are redacted, not printed.** These payloads carry OTP codes,
/// Aadhaar numbers, bank account numbers, PANs and bearer tokens. Logging any
/// of them verbatim would turn a debugging convenience into a data leak that
/// outlives the session, so [_redact] replaces them by key. The keys come from
/// the API's own field names — see the KYC details endpoint.
///
/// **3. Bodies are capped.** A KYC response with a dozen documents runs to
/// several kilobytes; `debugPrint` throttles long lines and would swallow the
/// status line that actually matters.
class ApiLog {
  const ApiLog._();

  static const int _maxBodyChars = 1200;

  /// Field names never printed in full, whatever they are nested inside.
  static const Set<String> _secrets = <String>{
    'code',
    'access_token',
    'refresh_token',
    'aadhaar_number',
    'pan',
    'bank_account_number',
    'bank_ifsc',
    'bank_account_name',
    'driving_licence_no',
    'debug_code',
    'password',
    'token',
  };

  static void request(String method, Uri uri, Object? body) {
    if (!kDebugMode) return;
    final String tail = body == null ? '' : ' ${_body(body)}';
    debugPrint('→ $method ${_path(uri)}$tail');
  }

  static void upload(
    Uri uri,
    Map<String, String> fields,
    String filename,
    int bytes,
  ) {
    if (!kDebugMode) return;
    final String kb = (bytes / 1024).toStringAsFixed(0);
    debugPrint(
      '→ POST ${_path(uri)} multipart ${_body(fields)} '
      'file=$filename ${kb}KB',
    );
  }

  static void response(
    String method,
    Uri uri,
    int status,
    String rawBody,
    Duration elapsed,
  ) {
    if (!kDebugMode) return;
    // The arrow makes failures scannable in a wall of logcat noise.
    final String mark = status >= 200 && status < 300 ? '←' : '✗';
    debugPrint(
      '$mark $status $method ${_path(uri)} '
      '(${elapsed.inMilliseconds}ms) ${_body(rawBody)}',
    );
  }

  static void failure(String method, Uri uri, Object error) {
    if (!kDebugMode) return;
    debugPrint('✗ --- $method ${_path(uri)} $error');
  }

  /// Path plus query only. The host is the same on every line and just pushes
  /// the interesting part off the right of a narrow terminal.
  static String _path(Uri uri) =>
      uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;

  /// Redacts, encodes and truncates. Falls back to a length marker rather than
  /// dumping an unparseable body — an HTML error page is not worth 1200
  /// characters of console.
  static String _body(Object? body) {
    Object? decoded = body;
    if (body is String) {
      if (body.isEmpty) return '(empty)';
      try {
        decoded = jsonDecode(body);
      } on FormatException {
        return '(${body.length} chars, not JSON)';
      }
    }

    final String encoded = jsonEncode(_redact(decoded));
    return encoded.length <= _maxBodyChars
        ? encoded
        : '${encoded.substring(0, _maxBodyChars)}…';
  }

  /// Walks maps and lists, replacing any [_secrets] value with a marker that
  /// still says whether something was there — "was the code empty?" is a real
  /// question when debugging, and `***` answers it without leaking the code.
  static Object? _redact(Object? value) {
    if (value is Map) {
      return <String, Object?>{
        for (final MapEntry<Object?, Object?> e in value.entries)
          '${e.key}': _secrets.contains('${e.key}')
              ? _mask(e.value)
              : _redact(e.value),
      };
    }
    if (value is List) {
      return <Object?>[for (final Object? item in value) _redact(item)];
    }
    return value;
  }

  static String _mask(Object? value) {
    if (value == null) return 'null';
    final int length = '$value'.length;
    return '***($length)';
  }
}
