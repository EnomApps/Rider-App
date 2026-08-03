import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/kyc_models.dart';
import '../data/picked_document.dart';
import '../data/rider_failure.dart';
import '../data/rider_profile.dart';
import '../data/rider_repository.dart';

/// Where a signed-in rider belongs right now.
///
/// This is the whole difference between the rider app and the customer app.
/// A customer is `active` the moment they verify a code and goes straight to
/// the home screen; a rider is `pending` and has to be walked through
/// onboarding and then wait for an admin.
enum RiderStage {
  /// The first fetch has not landed yet.
  loading,

  /// Nothing fetched and the fetch failed. Distinct from [loading] so the UI
  /// can offer a retry rather than spinning forever.
  unavailable,

  /// Details or documents still outstanding — show the wizard.
  onboarding,

  /// Everything sent, an admin has not decided. Read-only waiting room.
  underReview,

  /// Turned down. The wizard reopens with the reason at the top.
  rejected,

  /// `can_accept_orders` is true. The main UI is unlocked.
  ready,

  /// Verified on paper but the API still will not dispatch this rider —
  /// a lapsed licence or insurance, or a suspended account. The home screen
  /// opens in a blocked state rather than pretending the toggle will work.
  blocked,
}

/// Owns the rider profile, the KYC file, and the gate on the main UI.
///
/// Mirrors `AuthController`'s contract deliberately: every action returns
/// `null` on success or a [RiderFailure] on rejection, so screens neither catch
/// exceptions nor build error strings.
class RiderController extends ChangeNotifier {
  RiderController({required RiderRepository repository})
      : _repository = repository;

  final RiderRepository _repository;

  RiderProfile? _profile;
  KycOverview _kyc = KycOverview.empty;

  bool _isLoading = false;
  bool _isSaving = false;

  /// True once a fetch has landed. Distinct from [_attempted]: a load that
  /// failed has been attempted but has nothing to show.
  bool _hasLoaded = false;

  /// True once a fetch has finished, successfully or not. Without it a failed
  /// first load is indistinguishable from a load still in flight, and the gate
  /// would spin forever instead of offering a retry.
  bool _attempted = false;

  /// The types currently in flight, so each document row can spin on its own
  /// while the rest of the checklist stays usable.
  final Set<String> _uploading = <String>{};

  /// Field errors from the last 422, keyed exactly as the API keys them
  /// (`aadhaar_number`, `bank_ifsc`, …). The form screens look their fields up
  /// here so a server rejection lands on the right box.
  Map<String, List<String>> _fieldErrors = const <String, List<String>>{};

  /// Why the last [load] failed, so the retry screen can say something more
  /// useful than "check your connection" when the network was never the
  /// problem.
  RiderFailure? _loadFailure;

  RiderProfile? get profile => _profile;

  KycOverview get kyc => _kyc;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  bool get hasLoaded => _hasLoaded;

  Map<String, List<String>> get fieldErrors => _fieldErrors;

  RiderFailure? get loadFailure => _loadFailure;

  bool isUploading(String type) => _uploading.contains(type);

  /// True when there is nothing to show and nothing on its way.
  ///
  /// The gate reads this on every build rather than loading once in
  /// `initState`, so a controller that has been replaced — or reset by a
  /// sign-out and then signed back into — fetches itself instead of leaving
  /// the gate spinning on an empty profile forever. `_attempted` is what stops
  /// it retrying a failed load in a loop; the retry button drives that.
  bool get shouldLoad => _profile == null && !_isLoading && !_attempted;

  String? fieldError(String field) {
    final List<String>? messages = _fieldErrors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  void clearFieldErrors() {
    if (_fieldErrors.isEmpty) return;
    _fieldErrors = const <String, List<String>>{};
    notifyListeners();
  }

  /// The gate. Everything that decides where a rider lands is here, in one
  /// expression, rather than spread across the screens that navigate.
  RiderStage get stage {
    final RiderProfile? profile = _profile;
    if (profile == null) {
      return _attempted && !_isLoading
          ? RiderStage.unavailable
          : RiderStage.loading;
    }

    // The API's own verdict wins over everything below it. It weighs document
    // expiry and account status as well as the KYC decision, so a client that
    // second-guessed it would eventually be wrong in the permissive direction.
    if (profile.canAcceptOrders) return RiderStage.ready;

    switch (profile.kyc.status) {
      case KycStatus.verified:
        // Verified but still not dispatchable — expired papers, or suspended.
        return RiderStage.blocked;
      case KycStatus.submitted:
        return RiderStage.underReview;
      case KycStatus.rejected:
        return RiderStage.rejected;
      case KycStatus.pending:
      case KycStatus.unknown:
        return RiderStage.onboarding;
    }
  }

  /// True once every detail step and every required document is done, so the
  /// wizard can offer Submit. [KycOverview.canSubmit] is the server's own
  /// verdict and is the one that counts; the profile checks below only stop
  /// the app offering a button the API is certain to refuse.
  /// True while the rider may add or replace a file on the checklist.
  ///
  /// Wider than [KycStatusX.isEditable] by one case: a rider whose KYC is
  /// `verified` but whose licence or insurance has lapsed. Their reference
  /// numbers are locked — the API refuses to let an approved rider swap in a
  /// different licence — but a current photograph of the same licence is
  /// exactly what they need to upload to get back on the road.
  bool get canEditDocuments {
    if (_kyc.status.isEditable) return true;
    return _profile?.kyc.documentsExpired ?? false;
  }

  bool get canSubmit {
    final RiderProfile? profile = _profile;
    if (profile == null) return false;
    return _kyc.canSubmit && profile.hasIdentity && profile.hasVehicle;
  }

  // --- Loading -------------------------------------------------------------

  /// Fetches the profile and the KYC file together.
  ///
  /// Both are needed before the app can decide which screen to show, and they
  /// are independent, so they go out in parallel — this runs on the critical
  /// path straight after sign-in.
  Future<RiderFailure?> load({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.profile(),
        _repository.kyc(),
      ]);
      _profile = results[0] as RiderProfile;
      _kyc = results[1] as KycOverview;
      _hasLoaded = true;
      _loadFailure = null;
      return null;
    } on ApiException catch (error) {
      // A rider whose account exists but whose rider row does not is not an
      // error — it is a rider who has not started onboarding. The API has no
      // profile to return until the first `PATCH /v1/rider/profile` creates
      // one, so a 404 means "show the wizard", not "something went wrong".
      if (error.statusCode == 404) {
        _profile = _emptyProfile();
        _kyc = KycOverview.empty;
        _hasLoaded = true;
        _loadFailure = null;
        return null;
      }

      // Anything else genuinely failed. The gate reports `unavailable` and the
      // screen offers a retry.
      _hasLoaded = _profile != null;
      _loadFailure = riderFailureFrom(
        error,
        // The rider routes are role-gated, so a 403 here means the signed-in
        // account is not a rider. It cannot mean "documents under review" —
        // that is what `duty-status` answers with, and telling someone their
        // documents are being verified before they have uploaded any is worse
        // than saying nothing.
        forbiddenFailure: RiderFailure.notARider,
      );
      assert(() {
        debugPrint(
          'RiderController.load failed: ${error.statusCode} '
          '${error.kind.name} — ${error.message}',
        );
        return true;
      }());
      return _loadFailure;
    } catch (_) {
      _hasLoaded = _profile != null;
      _loadFailure = RiderFailure.unknown;
      return _loadFailure;
    } finally {
      _isLoading = false;
      _attempted = true;
      notifyListeners();
    }
  }

  /// Stands in for a rider row the backend has not created yet.
  ///
  /// Every field is the zero value onboarding starts from, so `stage` resolves
  /// to `onboarding` and the wizard opens on step 1. The first save replaces
  /// this with the real thing.
  RiderProfile _emptyProfile() => const RiderProfile(
        id: 0,
        fullName: '',
        vehicleType: VehicleType.unknown,
        kyc: RiderKycSummary.empty,
        dutyStatus: DutyStatus.offline,
        canAcceptOrders: false,
        completedDeliveries: 0,
      );

  /// Pull-to-refresh and the "check again" button on the waiting screen.
  Future<RiderFailure?> refresh() => load(silent: true);

  // --- Onboarding steps ----------------------------------------------------

  /// Step 1 — who the rider is. `PATCH /v1/rider/profile`.
  Future<RiderFailure?> saveIdentity({
    required String fullName,
    DateTime? dateOfBirth,
  }) {
    return _save(() async {
      _profile = await _repository.updateProfile(
        fullName: fullName,
        dateOfBirth: dateOfBirth,
      );
    });
  }

  /// Step 2 — the vehicle.
  ///
  /// Two calls, because the number lives in two places: `rider/profile` owns
  /// the vehicle the rider rides, `kyc/details` owns the number printed on the
  /// RC. Sending only one of them leaves the file inconsistent and the API
  /// refuses the submit later with no obvious cause.
  Future<RiderFailure?> saveVehicle({
    required VehicleType vehicleType,
    required String vehicleNumber,
    String? rcNumber,
  }) {
    return _save(() async {
      _profile = await _repository.updateProfile(
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
      );
      await _repository.updateKycDetails(
        KycDetails(vehicleNumber: vehicleNumber, rcNumber: rcNumber),
      );
    });
  }

  /// Steps 3-5 — the reference numbers. `PATCH /v1/rider/kyc/details`.
  ///
  /// Refetches the KYC file afterwards because `can_submit` and
  /// `missing_documents` are recomputed server-side on every change.
  Future<RiderFailure?> saveDetails(KycDetails details) {
    return _save(() async {
      await _repository.updateKycDetails(details);
      _kyc = await _repository.kyc();
    });
  }

  // --- Documents -----------------------------------------------------------

  /// Uploads one file against [type], replacing whatever was there.
  ///
  /// The old file is deleted first when one exists. The API keys a document by
  /// type, so uploading twice without deleting would either 422 or leave two
  /// rows for the same slot, and neither is recoverable from inside the app.
  Future<RiderFailure?> uploadDocument({
    required String type,
    required PickedDocument file,
  }) async {
    if (_uploading.contains(type)) return null;
    _uploading.add(type);
    notifyListeners();

    try {
      final KycDocument? existing = _kyc.documentOf(type);
      if (existing != null) {
        await _repository.deleteDocument(existing.id);
      }
      await _repository.uploadDocument(type: type, file: file);
      _kyc = await _repository.kyc();
      return null;
    } on ApiException catch (error) {
      return riderFailureFrom(
        error,
        validationFailure: RiderFailure.uploadRejected,
      );
    } catch (_) {
      return RiderFailure.uploadRejected;
    } finally {
      _uploading.remove(type);
      notifyListeners();
    }
  }

  Future<RiderFailure?> deleteDocument(String type) async {
    final KycDocument? existing = _kyc.documentOf(type);
    if (existing == null) return null;

    if (_uploading.contains(type)) return null;
    _uploading.add(type);
    notifyListeners();

    try {
      await _repository.deleteDocument(existing.id);
      _kyc = await _repository.kyc();
      return null;
    } on ApiException catch (error) {
      return riderFailureFrom(error);
    } catch (_) {
      return RiderFailure.unknown;
    } finally {
      _uploading.remove(type);
      notifyListeners();
    }
  }

  // --- Submission ----------------------------------------------------------

  /// `POST /v1/rider/kyc/submit`, then refetches the profile.
  ///
  /// The profile refetch is what moves [stage] to `underReview`; without it the
  /// app would still be showing the wizard over an already-submitted file.
  Future<RiderFailure?> submit() {
    return _save(
      onValidation: RiderFailure.cannotSubmitYet,
      () async {
        _kyc = await _repository.submitKyc();
        _profile = await _repository.profile();
      },
    );
  }

  // --- Duty ----------------------------------------------------------------

  /// `POST /v1/rider/duty-status`.
  ///
  /// A 403 here is meaningful rather than exceptional: the API refuses to
  /// dispatch a rider whose licence or insurance has lapsed, and that is
  /// exactly what the home screen needs to say out loud.
  Future<RiderFailure?> setDutyStatus(DutyStatus status) {
    return _save(() async {
      _profile = await _repository.setDutyStatus(status);
    });
  }

  // --- Plumbing ------------------------------------------------------------

  /// Runs [action] with the saving flag held, mapping transport errors onto the
  /// rider vocabulary and capturing 422 field errors for the forms.
  Future<RiderFailure?> _save(
    Future<void> Function() action, {
    RiderFailure onValidation = RiderFailure.invalidDetails,
  }) async {
    if (_isSaving) return RiderFailure.unknown;
    _isSaving = true;
    _fieldErrors = const <String, List<String>>{};
    notifyListeners();

    try {
      await action();
      return null;
    } on ApiException catch (error) {
      if (error.isValidation) _fieldErrors = error.errors;
      return riderFailureFrom(error, validationFailure: onValidation);
    } catch (_) {
      return RiderFailure.unknown;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Drops everything on sign-out, so the next rider to sign in on this device
  /// never sees the previous one's KYC file.
  void reset() {
    _profile = null;
    _kyc = KycOverview.empty;
    _hasLoaded = false;
    _attempted = false;
    _isLoading = false;
    _isSaving = false;
    _uploading.clear();
    _fieldErrors = const <String, List<String>>{};
    _loadFailure = null;
    notifyListeners();
  }
}
