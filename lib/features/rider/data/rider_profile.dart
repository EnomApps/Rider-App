import 'package:flutter/foundation.dart';

import 'kyc_models.dart';

/// The vehicle types `PATCH /v1/rider/profile` accepts.
enum VehicleType {
  walk,
  bicycle,
  motorcycle,
  scooter,
  ev,
  unknown;

  static VehicleType fromWire(Object? raw) {
    for (final VehicleType value in VehicleType.values) {
      if (value.name == raw) return value;
    }
    return VehicleType.unknown;
  }

  /// The five the picker offers. [unknown] exists only to survive a value this
  /// build predates and must never be selectable.
  static const List<VehicleType> selectable = <VehicleType>[
    VehicleType.motorcycle,
    VehicleType.scooter,
    VehicleType.ev,
    VehicleType.bicycle,
    VehicleType.walk,
  ];

  /// Whether this vehicle comes with papers: a number plate, an RC book, a
  /// licence and an insurance policy.
  ///
  /// A rider on foot or on a bicycle has none of them and cannot obtain them,
  /// so the fields and the whole licence step are skipped rather than shown
  /// and left empty — an onboarding that demands an RC book for a pair of
  /// shoes is one nobody finishes. Aadhaar and PAN are still asked for, and
  /// which documents must be uploaded stays the server's call:
  /// `required_documents` is never second-guessed here.
  bool get hasPapers => switch (this) {
        VehicleType.motorcycle || VehicleType.scooter || VehicleType.ev => true,
        VehicleType.walk || VehicleType.bicycle => false,
        // A type this build predates is treated as motorised: asking a rider
        // for papers they happen to have is recoverable, letting one onto the
        // road without the papers they need is not.
        VehicleType.unknown => true,
      };
}

/// The KYC block nested inside `RiderResource`.
///
/// Aadhaar and bank details are hidden on the model server-side and never
/// returned — only whether they are on file — so there is nothing to decode
/// for them here.
@immutable
class RiderKycSummary {
  const RiderKycSummary({
    required this.status,
    required this.documentsExpired,
    this.rejectionReason,
    this.pan,
    this.drivingLicenceNo,
    this.drivingLicenceExpiry,
    this.insuranceExpiry,
    this.verifiedAt,
  });

  final KycStatus status;

  /// True when the licence or the insurance has lapsed. The API refuses to put
  /// a rider on duty in that state, so the home screen surfaces it directly
  /// rather than letting the toggle fail with a 403.
  final bool documentsExpired;

  final String? rejectionReason;
  final String? pan;
  final String? drivingLicenceNo;
  final DateTime? drivingLicenceExpiry;
  final DateTime? insuranceExpiry;
  final DateTime? verifiedAt;

  static const RiderKycSummary empty = RiderKycSummary(
    status: KycStatus.pending,
    documentsExpired: false,
  );

  static RiderKycSummary fromJson(Map<String, dynamic> json) {
    return RiderKycSummary(
      status: _status(json['status']),
      documentsExpired: json['documents_expired'] as bool? ?? false,
      // Through `nullableString`, not a plain cast: the API sends the literal
      // string "null" for these when they are unset. See its doc comment —
      // taking that at face value makes the wizard skip a step the rider has
      // never filled in.
      rejectionReason: nullableString(json['rejection_reason']),
      pan: nullableString(json['pan']),
      drivingLicenceNo: nullableString(json['driving_licence_no']),
      drivingLicenceExpiry:
          DateTime.tryParse('${json['driving_licence_expiry']}'),
      insuranceExpiry: DateTime.tryParse('${json['insurance_expiry']}'),
      verifiedAt: DateTime.tryParse('${json['verified_at']}'),
    );
  }

  static KycStatus _status(Object? raw) {
    for (final KycStatus value in KycStatus.values) {
      if (value.name == raw) return value;
    }
    return KycStatus.unknown;
  }
}

/// `GET /v1/rider/profile`, decoded from `RiderResource`.
@immutable
class RiderProfile {
  const RiderProfile({
    required this.id,
    required this.fullName,
    required this.vehicleType,
    required this.kyc,
    required this.dutyStatus,
    required this.canGoOnline,
    required this.canAcceptOrders,
    required this.completedDeliveries,
    this.offlineReason,
    this.dateOfBirth,
    this.zoneId,
    this.vehicleNumber,
    this.rating,
    this.createdAt,
  });

  final int id;
  final String fullName;
  final DateTime? dateOfBirth;
  final int? zoneId;
  final VehicleType vehicleType;
  final String? vehicleNumber;
  final RiderKycSummary kyc;
  final DutyStatus dutyStatus;

  /// May this rider go on duty at all? The paperwork question.
  ///
  /// True once an admin has verified them and nothing has lapsed since, and it
  /// stays true while they are offline — which is the whole point, because
  /// that is exactly when the rider is looking at the Go online button.
  ///
  /// This is the gate on the main UI and on the duty toggle. Not
  /// [canAcceptOrders]: that one folds in `duty_status == available`, so it is
  /// false for every offline rider no matter how good their papers are, and
  /// gating the button on it means the button can never unlock itself.
  final bool canGoOnline;

  /// Why they cannot, in the server's own words, or null when nothing is
  /// blocking.
  ///
  /// The one string in this app rendered verbatim rather than translated. It
  /// is the same text `POST /v1/rider/duty-status` returns in its 403, so
  /// showing it as-is is what stops the banner and the error contradicting
  /// each other — a rider told two different reasons has no idea which to act
  /// on. See README > Localisation for the cost of that decision.
  final String? offlineReason;

  /// The API's own verdict on whether this rider may be dispatched **right
  /// now**, which includes being online already.
  ///
  /// Right for the order board and the Accept button, wrong for anything a
  /// rider touches while offline. Never recomputed client-side from the KYC
  /// status: the server also weighs document expiry and account suspension,
  /// and a client that guesses would eventually guess wrong in the permissive
  /// direction.
  final bool canAcceptOrders;

  final int completedDeliveries;

  /// Sent as a string by the API (a decimal cast), or null before the first
  /// rated delivery.
  final String? rating;

  final DateTime? createdAt;

  bool get isOnDuty => dutyStatus == DutyStatus.available;

  /// True once the rider has told us who they are. An account created by OTP
  /// alone has no name, so this is what the wizard's first step checks.
  bool get hasIdentity => fullName.trim().isNotEmpty;

  /// True once the vehicle step is answered.
  bool get hasVehicle => vehicleType != VehicleType.unknown;

  static RiderProfile fromJson(Map<String, dynamic> json) {
    final Object? vehicle = json['vehicle'];
    final Map<String, dynamic> vehicleMap =
        vehicle is Map<String, dynamic> ? vehicle : const <String, dynamic>{};

    final Object? kyc = json['kyc'];

    return RiderProfile(
      id: _int(json['id']),
      fullName: nullableString(json['full_name']) ?? '',
      dateOfBirth: DateTime.tryParse('${json['date_of_birth']}'),
      zoneId: json['zone_id'] is int ? json['zone_id'] as int : null,
      vehicleType: VehicleType.fromWire(vehicleMap['type']),
      vehicleNumber: nullableString(vehicleMap['number']),
      kyc: kyc is Map<String, dynamic>
          ? RiderKycSummary.fromJson(kyc)
          : RiderKycSummary.empty,
      dutyStatus: DutyStatus.fromWire(json['duty_status']),
      canAcceptOrders: json['can_accept_orders'] as bool? ?? false,
      // Falls back to `can_accept_orders` rather than to a guess. A server
      // that predates this field is the old contract, where that was the only
      // verdict on offer, so this behaves exactly as the app did before it —
      // conservatively, and never wrong in the permissive direction. Deriving
      // it from `kyc.verified` instead would put a rider with a lapsed licence
      // on the road the moment the backend rolled back.
      canGoOnline: json['can_go_online'] as bool? ??
          (json['can_accept_orders'] as bool? ?? false),
      // Through `nullableString`: this API sends the literal string "null" for
      // unset text fields, and a banner reading "null" is worse than no banner.
      offlineReason: nullableString(json['offline_reason']),
      completedDeliveries: _int(json['completed_deliveries']),
      rating: nullableString(json['rating']),
      createdAt: DateTime.tryParse('${json['created_at']}'),
    );
  }

  static int _int(Object? raw) => raw is int ? raw : int.tryParse('$raw') ?? 0;
}

/// The eleven reference numbers `PATCH /v1/rider/kyc/details` accepts.
///
/// Every field is optional on the wire, which lets the wizard save one step at
/// a time instead of holding an eleven-field form hostage until the last box
/// is filled. [toJson] drops nulls so a partial save never blanks a value the
/// rider entered on an earlier step.
@immutable
class KycDetails {
  const KycDetails({
    this.aadhaarNumber,
    this.pan,
    this.drivingLicenceNo,
    this.drivingLicenceExpiry,
    this.vehicleNumber,
    this.rcNumber,
    this.insuranceNumber,
    this.insuranceExpiry,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankIfsc,
  });

  final String? aadhaarNumber;
  final String? pan;
  final String? drivingLicenceNo;
  final DateTime? drivingLicenceExpiry;
  final String? vehicleNumber;
  final String? rcNumber;
  final String? insuranceNumber;
  final DateTime? insuranceExpiry;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankIfsc;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (aadhaarNumber != null) 'aadhaar_number': aadhaarNumber,
        if (pan != null) 'pan': pan,
        if (drivingLicenceNo != null) 'driving_licence_no': drivingLicenceNo,
        if (drivingLicenceExpiry != null)
          'driving_licence_expiry': _date(drivingLicenceExpiry!),
        if (vehicleNumber != null) 'vehicle_number': vehicleNumber,
        if (rcNumber != null) 'rc_number': rcNumber,
        if (insuranceNumber != null) 'insurance_number': insuranceNumber,
        if (insuranceExpiry != null)
          'insurance_expiry': _date(insuranceExpiry!),
        if (bankAccountName != null) 'bank_account_name': bankAccountName,
        if (bankAccountNumber != null)
          'bank_account_number': bankAccountNumber,
        if (bankIfsc != null) 'bank_ifsc': bankIfsc,
      };

  /// `YYYY-MM-DD`. The schema says `date-time`, but Laravel's `date` rule
  /// parses the short form and it avoids shipping a timezone the API would
  /// only discard — a licence expires on a date, not at an instant.
  static String _date(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
