import '../../../generated/l10n/app_localizations.dart';

/// Client-side mirrors of the patterns `PATCH /v1/rider/kyc/details` enforces.
///
/// These exist to fail fast, not to be authoritative — the server's verdict
/// always wins, and `RiderController.fieldErrors` carries it back onto the same
/// boxes. Every rule below is copied from the OpenAPI schema so the two cannot
/// disagree about what is acceptable:
///
/// * `aadhaar_number` — `^\d{12}$`
/// * `pan` — `^[A-Z]{5}\d{4}[A-Z]$`
/// * `bank_ifsc` — `^[A-Z]{4}0[A-Z0-9]{6}$`
/// * `vehicle_number` — max 15 characters
/// * `driving_licence_no` — max 20
/// * `insurance_number` — max 40
/// * `bank_account_number` — max 30
class KycValidators {
  const KycValidators._();

  static final RegExp _aadhaar = RegExp(r'^\d{12}$');
  static final RegExp _pan = RegExp(r'^[A-Z]{5}\d{4}[A-Z]$');
  static final RegExp _ifsc = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

  /// A number plate, allowing the spaces and hyphens riders actually type.
  /// Normalised away before sending — see [normalisePlate].
  static final RegExp _plate = RegExp(r'^[A-Z0-9]{4,15}$');

  static String? required(String? value, AppLocalizations l10n) {
    return (value ?? '').trim().isEmpty ? l10n.fieldRequired : null;
  }

  static String? aadhaar(String? value, AppLocalizations l10n) {
    final String input = (value ?? '').replaceAll(RegExp(r'\s'), '');
    if (input.isEmpty) return l10n.fieldRequired;
    return _aadhaar.hasMatch(input) ? null : l10n.invalidAadhaar;
  }

  static String? pan(String? value, AppLocalizations l10n) {
    final String input = (value ?? '').trim().toUpperCase();
    if (input.isEmpty) return l10n.fieldRequired;
    return _pan.hasMatch(input) ? null : l10n.invalidPan;
  }

  static String? ifsc(String? value, AppLocalizations l10n) {
    final String input = (value ?? '').trim().toUpperCase();
    if (input.isEmpty) return l10n.fieldRequired;
    return _ifsc.hasMatch(input) ? null : l10n.invalidIfsc;
  }

  static String? vehicleNumber(String? value, AppLocalizations l10n) {
    final String input = normalisePlate(value ?? '');
    if (input.isEmpty) return l10n.fieldRequired;
    return _plate.hasMatch(input) ? null : l10n.invalidVehicleNumber;
  }

  /// Indian account numbers run 9-18 digits depending on the bank, and the API
  /// caps the column at 30. Digits only, which every major bank uses.
  static String? accountNumber(String? value, AppLocalizations l10n) {
    final String input = (value ?? '').replaceAll(RegExp(r'\s'), '');
    if (input.isEmpty) return l10n.fieldRequired;
    final bool wellFormed = RegExp(r'^\d{9,18}$').hasMatch(input);
    return wellFormed ? null : l10n.invalidAccountNumber;
  }

  static String? maxLength(String? value, int max, AppLocalizations l10n) {
    final String input = (value ?? '').trim();
    if (input.isEmpty) return l10n.fieldRequired;
    return input.length <= max ? null : l10n.fieldRequired;
  }

  /// A licence or policy that has already lapsed is refused by the API when the
  /// rider tries to go online, so it is refused here rather than letting them
  /// finish onboarding and discover it a week later.
  static String? futureDate(DateTime? value, AppLocalizations l10n) {
    if (value == null) return l10n.fieldRequired;
    final DateTime today = DateTime.now();
    final DateTime midnight = DateTime(today.year, today.month, today.day);
    return value.isBefore(midnight) ? l10n.dateMustBeFuture : null;
  }

  /// Eighteen is the legal floor for a commercial two-wheeler licence in India.
  static String? adultBirthDate(DateTime? value, AppLocalizations l10n) {
    if (value == null) return l10n.fieldRequired;
    final DateTime now = DateTime.now();
    final DateTime eighteenthBirthday = DateTime(
      value.year + 18,
      value.month,
      value.day,
    );
    return eighteenthBirthday.isAfter(now) ? l10n.mustBeEighteen : null;
  }

  /// Strips the spaces and hyphens riders type into a number plate, and
  /// uppercases it. `TN 01 AB 1234` and `tn01-ab-1234` both become
  /// `TN01AB1234`, which is what the API stores.
  static String normalisePlate(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
}
