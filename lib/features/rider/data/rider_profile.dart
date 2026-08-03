import 'package:flutter/foundation.dart';

import 'kyc_models.dart';

/// The vehicle types `PATCH /v1/rider/profile` accepts.
enum VehicleType {
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

  /// The four the picker offers. [unknown] exists only to survive a value this
  /// build predates and must never be selectable.
  static const List<VehicleType> selectable = <VehicleType>[
    VehicleType.motorcycle,
    VehicleType.scooter,
    VehicleType.ev,
    VehicleType.bicycle,
  ];
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
      rejectionReason: json['rejection_reason'] as String?,
      pan: json['pan'] as String?,
      drivingLicenceNo: json['driving_licence_no'] as String?,
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
    required this.canAcceptOrders,
    required this.completedDeliveries,
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

  /// The API's own verdict on whether this rider may be dispatched, and the
  /// single gate on the main UI. Never recomputed client-side from the KYC
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
      fullName: json['full_name'] as String? ?? '',
      dateOfBirth: DateTime.tryParse('${json['date_of_birth']}'),
      zoneId: json['zone_id'] is int ? json['zone_id'] as int : null,
      vehicleType: VehicleType.fromWire(vehicleMap['type']),
      vehicleNumber: vehicleMap['number'] as String?,
      kyc: kyc is Map<String, dynamic>
          ? RiderKycSummary.fromJson(kyc)
          : RiderKycSummary.empty,
      dutyStatus: DutyStatus.fromWire(json['duty_status']),
      canAcceptOrders: json['can_accept_orders'] as bool? ?? false,
      completedDeliveries: _int(json['completed_deliveries']),
      rating: json['rating']?.toString(),
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
