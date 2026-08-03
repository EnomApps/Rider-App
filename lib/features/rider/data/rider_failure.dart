import '../../../core/network/api_exception.dart';
import '../../../generated/l10n/app_localizations.dart';

/// Every way a rider-surface call can fail, as a closed set.
///
/// Same contract as `AuthFailure`: the repository never returns a message, only
/// a case from this enum, so all error text comes from the ARB files and works
/// in every supported language. The API's own `message` fields are English-only
/// and are never rendered.
enum RiderFailure {
  /// 403 on `duty-status` — the licence or the insurance has lapsed. The rider
  /// has to upload current documents before going online.
  documentsExpired,

  /// 403 on `duty-status` — KYC is still with an admin.
  awaitingVerification,

  /// 422 — a field the server would not take. The screen shows the per-field
  /// errors alongside this.
  invalidDetails,

  /// 422 on `kyc/submit` — something is still outstanding.
  cannotSubmitYet,

  /// The upload was refused: wrong type, too large, or the server rejected it.
  uploadRejected,

  /// The session could not be restored or refreshed.
  sessionExpired,

  /// No connectivity, DNS failure or timeout.
  network,

  /// 429 — rate limited.
  tooManyRequests,

  /// 5xx, an unparseable body, or anything else unexpected.
  unknown,
}

extension RiderFailureMessage on RiderFailure {
  String message(AppLocalizations l10n) {
    switch (this) {
      case RiderFailure.documentsExpired:
        return l10n.documentsExpiredMessage;
      case RiderFailure.awaitingVerification:
        return l10n.awaitingVerificationMessage;
      case RiderFailure.invalidDetails:
        return l10n.checkTheHighlightedFields;
      case RiderFailure.cannotSubmitYet:
        return l10n.completeEverythingBeforeSubmitting;
      case RiderFailure.uploadRejected:
        return l10n.uploadFailed;
      case RiderFailure.sessionExpired:
        return l10n.sessionExpired;
      case RiderFailure.network:
        return l10n.networkError;
      case RiderFailure.tooManyRequests:
        return l10n.tooManyAttempts;
      case RiderFailure.unknown:
        return l10n.somethingWentWrong;
    }
  }
}

/// Maps a transport-level error onto the rider vocabulary.
///
/// [validationFailure] is what a 422 means for the call in question: a bad
/// field on `kyc/details`, an incomplete file on `kyc/submit`.
///
/// The 403 split reads the server's English message, which is the only thing
/// distinguishing "documents expired" from "still being verified" — the two
/// share a status code. The message is used to *choose a translated string*,
/// never rendered, and an unrecognised wording degrades to the more common of
/// the two rather than throwing.
RiderFailure riderFailureFrom(
  ApiException error, {
  RiderFailure validationFailure = RiderFailure.invalidDetails,
}) {
  switch (error.kind) {
    case ApiErrorKind.network:
      return RiderFailure.network;
    case ApiErrorKind.unauthenticated:
      return RiderFailure.sessionExpired;
    case ApiErrorKind.forbidden:
      final String message = error.message?.toLowerCase() ?? '';
      if (message.contains('expired')) return RiderFailure.documentsExpired;
      return RiderFailure.awaitingVerification;
    case ApiErrorKind.validation:
      return validationFailure;
    case ApiErrorKind.tooManyRequests:
      return RiderFailure.tooManyRequests;
    case ApiErrorKind.server:
      return RiderFailure.unknown;
  }
}
