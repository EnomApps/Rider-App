import '../../../core/network/api_client.dart';

/// Which of the two Nexmile apps this token belongs to.
///
/// The server routes on it, and this is the app where it matters most: an
/// `order.offer` posted to a customer's phone is noise, but the same offer
/// *not* reaching a rider's phone is an order going cold on a counter.
const String kPushAppName = 'rider';

/// The push registration endpoints.
///
/// Separate from `AuthRepository` on purpose: a device row belongs to the
/// session but is not the session, and this is called on token rotation as
/// well as at sign-in.
abstract class DeviceRepository {
  /// `POST /v1/devices` — after sign-in, on every token rotation, and once at
  /// launch on a restored session (the token may have rotated while the app
  /// was closed).
  ///
  /// Idempotent server-side: registering the same token twice is not an error.
  Future<void> registerDevice({
    required String token,
    required String platform,
  });

  /// `DELETE /v1/devices` — on sign-out, while the access token is still
  /// valid. After the session is cleared this call can only 401.
  Future<void> unregisterDevice({required String token});
}

class ApiDeviceRepository implements DeviceRepository {
  const ApiDeviceRepository(this._client);

  final ApiClient _client;

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) {
    return _client.post(
      '/v1/devices',
      body: <String, dynamic>{
        'token': token,
        'platform': platform,
        'app': kPushAppName,
      },
    );
  }

  @override
  Future<void> unregisterDevice({required String token}) {
    return _client.delete(
      '/v1/devices',
      body: <String, dynamic>{'token': token},
    );
  }
}
