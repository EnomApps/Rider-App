/// Build-time configuration.
///
/// Override the base URL without touching source:
///
/// ```bash
/// flutter run --dart-define=NEXMILE_API_BASE_URL=http://10.0.2.2:8000/api
/// ```
///
/// `10.0.2.2` is how the Android emulator reaches the host machine's
/// `localhost`; on a physical device use the machine's LAN address.
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'NEXMILE_API_BASE_URL',
    defaultValue: 'https://api.nexmile.in/api',
  );

  /// Sent as `intended_role` on `POST /v1/auth/otp/request`.
  ///
  /// This single line is what makes the shared OTP flow create a rider rather
  /// than a customer. The API only accepts the self-service roles here, so a
  /// merchant or admin account can never be created by asking for a code.
  static const String intendedRole = 'rider';

  /// Sent as `device_name` on OTP verification so the rider can recognise the
  /// session in the sessions list.
  static const String deviceNameFallback = 'Nexmile Rider app';

  static const Duration requestTimeout = Duration(seconds: 30);

  /// A KYC upload is a photograph, not a JSON body — give it its own, longer
  /// budget. A licence photo over a rural 3G connection routinely outlasts the
  /// 30 seconds that is generous for an API call.
  static const Duration uploadTimeout = Duration(seconds: 90);

  /// Ceiling the API enforces on a KYC upload. Checked client-side as well, so
  /// a rider is told immediately rather than after a five-megabyte upload
  /// comes back 422.
  static const int maxDocumentBytes = 5 * 1024 * 1024;

  /// File extensions `POST /v1/rider/kyc/documents` accepts.
  static const List<String> allowedDocumentExtensions = <String>[
    'jpg',
    'jpeg',
    'png',
    'pdf',
  ];
}
