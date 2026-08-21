import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'kyc_models.dart';
import 'order_models.dart';
import 'picked_document.dart';
import 'rider_profile.dart';

/// Everything under `/v1/rider`.
///
/// Kept as an interface so the onboarding flow can be driven by a fake in
/// tests without a live backend — the wizard has enough states (pending,
/// submitted, rejected, expired documents) that exercising them against a real
/// server would be impractical.
abstract class RiderRepository {
  /// `GET /v1/rider/profile`
  Future<RiderProfile> profile();

  /// `PATCH /v1/rider/profile` — name, date of birth and vehicle.
  ///
  /// KYC reference numbers are deliberately not editable here; they go through
  /// [updateKycDetails] so an approved rider cannot quietly swap in a
  /// different licence afterwards.
  Future<RiderProfile> updateProfile({
    String? fullName,
    DateTime? dateOfBirth,
    VehicleType? vehicleType,
    String? vehicleNumber,
  });

  /// `POST /v1/rider/duty-status`
  Future<RiderProfile> setDutyStatus(DutyStatus status);

  /// `GET /v1/rider/kyc`
  Future<KycOverview> kyc();

  /// `PATCH /v1/rider/kyc/details` — the eleven reference numbers.
  Future<void> updateKycDetails(KycDetails details);

  /// `POST /v1/rider/kyc/documents` (multipart)
  Future<KycDocument> uploadDocument({
    required String type,
    required PickedDocument file,
  });

  /// `DELETE /v1/rider/kyc/documents/{document}`
  Future<void> deleteDocument(int documentId);

  /// `POST /v1/rider/kyc/submit` — hands the file to an admin for review.
  Future<KycOverview> submitKyc();

  // --- Dispatch ------------------------------------------------------------

  /// `POST /v1/rider/location` — the position ping, and the heartbeat.
  ///
  /// Returns whether the server is still tracking this rider. An offline rider
  /// gets a 200 with `tracking: false` rather than an error, so the caller
  /// stops its timer instead of retrying something that will never succeed.
  Future<bool> sendLocation({
    required double latitude,
    required double longitude,
    double? accuracyMetres,
  });

  /// `GET /v1/rider/orders/available` — the board, nearest restaurant first.
  Future<OrderBoard> availableOrders();

  /// `GET /v1/rider/orders?active=1` — what this rider is carrying.
  ///
  /// The working screen resumes from this rather than from local state: a
  /// shift outlives an app process, and an order accepted before a crash is
  /// still the rider's when they reopen.
  Future<RiderOrder?> activeOrder();

  /// `GET /v1/rider/orders` — completed and cancelled work, newest first.
  Future<List<RiderOrder>> orderHistory({int perPage = 20});

  /// `GET /v1/rider/orders/{order}` — one order in full.
  Future<RiderOrder> order(String orderId);

  /// `POST /v1/rider/orders/{order}/accept` — first to accept wins.
  Future<RiderOrder> acceptOrder(String orderId);

  /// `POST /v1/rider/orders/{order}/pickup` — the merchant's four digits.
  Future<RiderOrder> confirmPickup(String orderId, String pickupCode);

  /// `POST /v1/rider/orders/{order}/release` — back on the board.
  Future<RiderOrder> releaseOrder(String orderId, {String? reason});

  /// `POST /v1/rider/orders/{order}/deliver` — closes it out.
  Future<RiderOrder> confirmDelivery(String orderId);
}

class ApiRiderRepository implements RiderRepository {
  const ApiRiderRepository(this._client);

  final ApiClient _client;

  @override
  Future<RiderProfile> profile() async {
    final Map<String, dynamic> response =
        await _client.get('/v1/rider/profile');
    return RiderProfile.fromJson(_data(response));
  }

  @override
  Future<RiderProfile> updateProfile({
    String? fullName,
    DateTime? dateOfBirth,
    VehicleType? vehicleType,
    String? vehicleNumber,
  }) async {
    final Map<String, dynamic> response = await _client.patch(
      '/v1/rider/profile',
      // ApiClient prunes nulls, so an unset argument is left untouched
      // server-side rather than being blanked.
      body: <String, dynamic>{
        'full_name': fullName,
        'date_of_birth':
            dateOfBirth == null ? null : _date(dateOfBirth),
        'vehicle_type': vehicleType?.name,
        'vehicle_number': vehicleNumber,
      },
    );
    return RiderProfile.fromJson(_data(response));
  }

  @override
  Future<RiderProfile> setDutyStatus(DutyStatus status) async {
    final Map<String, dynamic> response = await _client.post(
      '/v1/rider/duty-status',
      body: <String, dynamic>{'duty_status': status.wireValue},
    );
    return RiderProfile.fromJson(_data(response));
  }

  @override
  Future<KycOverview> kyc() async {
    final Map<String, dynamic> response = await _client.get('/v1/rider/kyc');
    return KycOverview.fromJson(_data(response));
  }

  @override
  Future<void> updateKycDetails(KycDetails details) async {
    final Map<String, dynamic> body = details.toJson();
    // Nothing to say — the step was left blank. A PATCH with an empty body
    // would still succeed, but the round trip is pure latency on a connection
    // that may not have it to spare.
    if (body.isEmpty) return;
    await _client.patch('/v1/rider/kyc/details', body: body);
  }

  @override
  Future<KycDocument> uploadDocument({
    required String type,
    required PickedDocument file,
  }) async {
    final Map<String, dynamic> response = await _client.upload(
      '/v1/rider/kyc/documents',
      field: 'file',
      bytes: file.bytes,
      filename: file.filename,
      contentType: file.mimeType,
      fields: <String, String>{'type': type},
    );
    final Object? data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        kind: ApiErrorKind.server,
        message: 'Upload response did not contain a document',
      );
    }
    return KycDocument.fromJson(data);
  }

  @override
  Future<void> deleteDocument(int documentId) async {
    await _client.delete('/v1/rider/kyc/documents/$documentId');
  }

  @override
  Future<KycOverview> submitKyc() async {
    final Map<String, dynamic> response =
        await _client.post('/v1/rider/kyc/submit');
    return KycOverview.fromJson(_data(response));
  }

  // --- Dispatch ------------------------------------------------------------

  @override
  Future<bool> sendLocation({
    required double latitude,
    required double longitude,
    double? accuracyMetres,
  }) async {
    final Map<String, dynamic> response = await _client.post(
      '/v1/rider/location',
      body: <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_metres': accuracyMetres,
      },
    );
    final Object? data = response['data'];
    if (data is Map<String, dynamic>) {
      return data['tracking'] as bool? ?? false;
    }
    // A 200 with a body this client cannot read is still a 200 — the ping
    // landed. Assuming it did not would stop the heartbeat over a response
    // shape, which is exactly how a rider silently drops out of dispatch.
    return true;
  }

  @override
  Future<OrderBoard> availableOrders() async {
    final Map<String, dynamic> response =
        await _client.get('/v1/rider/orders/available');
    return OrderBoard.fromJson(response);
  }

  @override
  Future<RiderOrder?> activeOrder() async {
    final Map<String, dynamic> response = await _client.get(
      '/v1/rider/orders',
      query: <String, String>{'active': '1'},
    );
    final List<RiderOrder> orders = _list(response);
    if (orders.isEmpty) return null;

    // `active=1` is the server's filter and it is the one that counts, but a
    // delivered order slipping through would pin the working screen open on a
    // job that is finished. Checking the status costs nothing and fails safe.
    for (final RiderOrder order in orders) {
      if (order.status.isActive) return order;
    }
    return null;
  }

  @override
  Future<List<RiderOrder>> orderHistory({int perPage = 20}) async {
    final Map<String, dynamic> response = await _client.get(
      '/v1/rider/orders',
      query: <String, String>{'per_page': '$perPage'},
    );
    return _list(response);
  }

  @override
  Future<RiderOrder> order(String orderId) async {
    final Map<String, dynamic> response =
        await _client.get('/v1/rider/orders/$orderId');
    return RiderOrder.fromJson(_data(response));
  }

  @override
  Future<RiderOrder> acceptOrder(String orderId) async {
    final Map<String, dynamic> response =
        await _client.post('/v1/rider/orders/$orderId/accept');
    return RiderOrder.fromJson(_data(response));
  }

  @override
  Future<RiderOrder> confirmPickup(String orderId, String pickupCode) async {
    final Map<String, dynamic> response = await _client.post(
      '/v1/rider/orders/$orderId/pickup',
      body: <String, dynamic>{'pickup_code': pickupCode},
    );
    return RiderOrder.fromJson(_data(response));
  }

  @override
  Future<RiderOrder> releaseOrder(String orderId, {String? reason}) async {
    final Map<String, dynamic> response = await _client.post(
      '/v1/rider/orders/$orderId/release',
      body: <String, dynamic>{'reason': reason},
    );
    return RiderOrder.fromJson(_data(response));
  }

  @override
  Future<RiderOrder> confirmDelivery(String orderId) async {
    final Map<String, dynamic> response =
        await _client.post('/v1/rider/orders/$orderId/deliver');
    return RiderOrder.fromJson(_data(response));
  }

  static String _date(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  /// A `data` array, for the endpoints that return a collection.
  static List<RiderOrder> _list(Map<String, dynamic> response) {
    final Object? data = response['data'];
    if (data is! List<Object?>) return const <RiderOrder>[];
    return <RiderOrder>[
      for (final Object? raw in data)
        if (raw is Map<String, dynamic>) RiderOrder.fromJson(raw),
    ];
  }

  /// Every success response wraps its payload in `data`.
  static Map<String, dynamic> _data(Map<String, dynamic> response) {
    final Object? data = response['data'];
    if (data is Map<String, dynamic>) return data;
    throw const ApiException(
      kind: ApiErrorKind.server,
      message: 'Response did not contain a data object',
    );
  }
}
