import '../../../core/network/api_exception.dart';
import '../../../generated/l10n/app_localizations.dart';

/// Every way customer sign-in can fail, as a closed set.
///
/// The repository never returns a message — only a case from this enum — so all
/// error text comes from the ARB files and works in every supported language.
/// The API's own `message` fields are English-only and are never shown.
enum AuthFailure {
  /// The server rejected the email or phone we sent (422 on `otp/request`).
  invalidIdentifier,

  /// Wrong or expired code (422 on `otp/verify`). Five wrong attempts burn the
  /// code and a fresh one has to be requested.
  incorrectCode,

  /// 403 — the account is suspended.
  accountSuspended,

  /// 429 — too many code requests or verification attempts.
  tooManyRequests,

  /// The session could not be restored or refreshed.
  sessionExpired,

  /// No connectivity, DNS failure or timeout.
  network,

  /// 5xx, an unparseable body, or anything else unexpected.
  unknown,
}

extension AuthFailureMessage on AuthFailure {
  String message(AppLocalizations l10n) {
    switch (this) {
      case AuthFailure.invalidIdentifier:
        return l10n.invalidEmailOrPhone;
      case AuthFailure.incorrectCode:
        return l10n.incorrectCode;
      case AuthFailure.accountSuspended:
        return l10n.accountSuspended;
      case AuthFailure.tooManyRequests:
        return l10n.tooManyAttempts;
      case AuthFailure.sessionExpired:
        return l10n.sessionExpired;
      case AuthFailure.network:
        return l10n.networkError;
      case AuthFailure.unknown:
        return l10n.somethingWentWrong;
    }
  }
}

/// Maps a transport-level error onto the auth vocabulary.
///
/// [validationFailure] is what a 422 means for the call in question: a bad
/// address on `otp/request`, a bad code on `otp/verify`.
AuthFailure authFailureFrom(
  ApiException error, {
  required AuthFailure validationFailure,
}) {
  switch (error.kind) {
    case ApiErrorKind.network:
      return AuthFailure.network;
    case ApiErrorKind.unauthenticated:
      return AuthFailure.sessionExpired;
    case ApiErrorKind.forbidden:
      return AuthFailure.accountSuspended;
    case ApiErrorKind.validation:
      return validationFailure;
    case ApiErrorKind.tooManyRequests:
      return AuthFailure.tooManyRequests;
    case ApiErrorKind.server:
      return AuthFailure.unknown;
  }
}
