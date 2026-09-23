import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../config/app_config.dart';
import 'api_exception.dart';
import 'api_log.dart';

/// Supplies the current access token and refreshes the pair on demand.
///
/// Implemented by the auth layer; kept as a callback bundle so the network
/// layer does not depend on the auth feature.
abstract class TokenProvider {
  String? get accessToken;

  /// Exchanges the stored refresh token for a new pair. Returns false when
  /// there is nothing to refresh with or the server rejected the attempt.
  Future<bool> refresh();

  /// Called when refreshing fails, so the app can drop the session.
  Future<void> onSessionLost();
}

/// Thin JSON client for the Nexmile API.
///
/// Two behaviours matter and are easy to get wrong:
///
/// * **`Accept: application/json` on every request.** The API docs are explicit:
///   without it a validation failure returns an HTML redirect rather than a 422
///   carrying the field errors.
/// * **Refreshes are serialised behind a single lock.** Two concurrent
///   refreshes look like a stolen token to the server and sign the customer out
///   of every device. [_refreshLock] holds the in-flight refresh so parallel
///   401s all await the same call, and each request is retried at most once.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    this.tokenProvider,
  })  : _http = httpClient ?? http.Client(),
        _baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).replaceAll(
          RegExp(r'/+$'),
          '',
        );

  final http.Client _http;
  final String _baseUrl;

  /// Null for endpoints that never authenticate (OTP request and verify).
  TokenProvider? tokenProvider;

  Future<bool>? _refreshLock;

  void close() => _http.close();

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
  }) {
    return _send(
      'GET',
      path,
      query: query,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send('POST', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send('PATCH', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    // Unusual for a DELETE, and needed by exactly one endpoint: unregistering
    // a push token identifies the row by the token rather than by an id.
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send('DELETE', path, body: body, authenticated: authenticated);
  }

  /// `multipart/form-data` POST — KYC document uploads.
  ///
  /// The file arrives as bytes rather than a path on purpose: a multipart
  /// request cannot be re-sent once its stream has been consumed, and this
  /// call has to survive the same 401-refresh-and-retry as every other. Bytes
  /// let the request be rebuilt from scratch for the retry.
  Future<Map<String, dynamic>> upload(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    String? contentType,
    Map<String, String> fields = const <String, String>{},
    bool isRetry = false,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl$path');

    final Stopwatch clock = Stopwatch()..start();
    late final http.Response response;
    try {
      final http.MultipartRequest request =
          http.MultipartRequest('POST', uri)
            ..headers['Accept'] = 'application/json'
            ..fields.addAll(fields)
            ..files.add(
              http.MultipartFile.fromBytes(
                field,
                bytes,
                filename: filename,
                contentType: _parseMediaType(contentType),
              ),
            );

      final String? token = tokenProvider?.accessToken;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      // Size and filename, never the bytes — a licence photo in the console
      // helps nobody and would take the log with it.
      assert(() {
        ApiLog.upload(uri, fields, filename, bytes.length);
        return true;
      }());

      final http.StreamedResponse streamed = await _http
          .send(request)
          .timeout(AppConfig.uploadTimeout);
      response = await http.Response.fromStream(streamed);
      assert(() {
        ApiLog.response(
            'POST', uri, response.statusCode, response.body, clock.elapsed);
        return true;
      }());
    } on TimeoutException catch (error) {
      assert(() {
        ApiLog.failure('POST', uri, error);
        return true;
      }());
      throw const ApiException(kind: ApiErrorKind.network);
    } on SocketException catch (error) {
      assert(() {
        ApiLog.failure('POST', uri, error);
        return true;
      }());
      throw const ApiException(kind: ApiErrorKind.network);
    } on http.ClientException catch (error) {
      assert(() {
        ApiLog.failure('POST', uri, error);
        return true;
      }());
      throw const ApiException(kind: ApiErrorKind.network);
    }

    if (response.statusCode == 401 && !isRetry) {
      final bool refreshed = await _refreshOnce();
      if (refreshed) {
        return upload(
          path,
          field: field,
          bytes: bytes,
          filename: filename,
          contentType: contentType,
          fields: fields,
          isRetry: true,
        );
      }
      await tokenProvider?.onSessionLost();
    }

    return _decode(response);
  }

  /// Hand-parses `type/subtype` so the network layer does not need a dependency
  /// on `http_parser` beyond what `http` already exposes. An unrecognised value
  /// yields null, which lets `http` fall back to `application/octet-stream` —
  /// the API sniffs the file anyway.
  static MediaType? _parseMediaType(String? raw) {
    if (raw == null) return null;
    final List<String> parts = raw.split('/');
    if (parts.length != 2) return null;
    if (parts[0].isEmpty || parts[1].isEmpty) return null;
    return MediaType(parts[0], parts[1]);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    required bool authenticated,
    bool isRetry = false,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: query,
    );

    final Map<String, String> headers = <String, String>{
      // Non-negotiable — see the class doc.
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };

    final String? token = tokenProvider?.accessToken;
    if (authenticated && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final Stopwatch clock = Stopwatch()..start();
    late final http.Response response;
    try {
      final http.Request request = http.Request(method, uri)
        ..headers.addAll(headers);
      final Map<String, dynamic>? pruned =
          body == null ? null : _pruneNulls(body);
      if (pruned != null) {
        request.body = jsonEncode(pruned);
      }
      // Logs what actually goes on the wire, after pruning — a body the client
      // dropped a key from is exactly the kind of thing worth seeing.
      assert(() {
        ApiLog.request(method, uri, pruned);
        return true;
      }());

      final http.StreamedResponse streamed = await _http
          .send(request)
          .timeout(AppConfig.requestTimeout);
      response = await http.Response.fromStream(streamed);
      assert(() {
        ApiLog.response(method, uri, response.statusCode, response.body,
            clock.elapsed);
        return true;
      }());
    } on TimeoutException catch (error) {
      assert(() {
        ApiLog.failure(method, uri, error);
        return true;
      }());
      throw const ApiException(kind: ApiErrorKind.network);
    } on SocketException catch (error) {
      assert(() {
        ApiLog.failure(method, uri, error);
        return true;
      }());
      throw const ApiException(kind: ApiErrorKind.network);
    } on http.ClientException catch (error) {
      assert(() {
        ApiLog.failure(method, uri, error);
        return true;
      }());
      throw const ApiException(kind: ApiErrorKind.network);
    }

    if (response.statusCode == 401 && authenticated && !isRetry) {
      final bool refreshed = await _refreshOnce();
      if (refreshed) {
        return _send(
          method,
          path,
          query: query,
          body: body,
          authenticated: authenticated,
          isRetry: true,
        );
      }
      await tokenProvider?.onSessionLost();
    }

    return _decode(response);
  }

  /// Runs at most one refresh at a time; concurrent callers await the same
  /// future rather than each firing their own.
  Future<bool> _refreshOnce() {
    final Future<bool>? inFlight = _refreshLock;
    if (inFlight != null) return inFlight;

    final TokenProvider? provider = tokenProvider;
    if (provider == null) return Future<bool>.value(false);

    final Future<bool> attempt = provider.refresh().whenComplete(() {
      _refreshLock = null;
    });
    _refreshLock = attempt;
    return attempt;
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> json = const <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) json = decoded;
      } on FormatException {
        // An HTML error page, most likely. Fall through to the status mapping
        // below rather than surfacing a parse error.
        json = const <String, dynamic>{};
      }
    }

    final int status = response.statusCode;
    if (status >= 200 && status < 300) return json;

    final String? message = json['message'] as String?;

    switch (status) {
      case 401:
        throw ApiException(
          kind: ApiErrorKind.unauthenticated,
          statusCode: status,
          message: message,
        );
      case 403:
        throw ApiException(
          kind: ApiErrorKind.forbidden,
          statusCode: status,
          message: message,
        );
      case 422:
        throw ApiException(
          kind: ApiErrorKind.validation,
          statusCode: status,
          message: message,
          errors: _parseErrors(json['errors']),
        );
      case 429:
        throw ApiException(
          kind: ApiErrorKind.tooManyRequests,
          statusCode: status,
          message: message,
        );
      default:
        throw ApiException(
          kind: ApiErrorKind.server,
          statusCode: status,
          message: message,
        );
    }
  }

  static Map<String, List<String>> _parseErrors(Object? raw) {
    if (raw is! Map) return const <String, List<String>>{};
    final Map<String, List<String>> parsed = <String, List<String>>{};
    raw.forEach((Object? key, Object? value) {
      if (key is! String) return;
      if (value is List) {
        parsed[key] = value.whereType<String>().toList();
      } else if (value is String) {
        parsed[key] = <String>[value];
      }
    });
    return parsed;
  }

  /// The API treats `email` and `phone` as mutually exclusive; sending one of
  /// them as an explicit null still counts as sending it.
  static Map<String, dynamic> _pruneNulls(Map<String, dynamic> body) {
    return <String, dynamic>{
      for (final MapEntry<String, dynamic> e in body.entries)
        if (e.value != null) e.key: e.value,
    };
  }
}
