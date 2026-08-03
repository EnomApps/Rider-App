/// Everything that can go wrong on a call to the Nexmile API, as a closed set.
///
/// Mapped from HTTP status codes in `ApiClient`; the UI turns each case into a
/// translated message so no English server string is ever shown to a user.
enum ApiErrorKind {
  /// No connectivity, DNS failure, or the request timed out.
  network,

  /// 401 — token missing, expired or revoked, and refreshing did not help.
  unauthenticated,

  /// 403 — authenticated but not allowed, or the account is suspended.
  forbidden,

  /// 422 — validation failed; see [ApiException.errors].
  validation,

  /// 429 — rate limited.
  tooManyRequests,

  /// 5xx, or a response body the client could not parse.
  server,
}

class ApiException implements Exception {
  const ApiException({
    required this.kind,
    this.statusCode,
    this.message,
    this.errors = const <String, List<String>>{},
  });

  final ApiErrorKind kind;
  final int? statusCode;

  /// The server's own `message`. Useful for logs — it is English-only, so it
  /// is never rendered directly.
  final String? message;

  /// 422 field errors, keyed by field name.
  final Map<String, List<String>> errors;

  /// First error recorded against [field], if any.
  String? errorFor(String field) {
    final List<String>? messages = errors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  bool get isValidation => kind == ApiErrorKind.validation;

  @override
  String toString() =>
      'ApiException(${kind.name}, status: $statusCode, message: $message, '
      'errors: $errors)';
}
