import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'payout_models.dart';

/// `/v1/rider/payouts` — the weekly pay statements.
///
/// Apart from `RiderRepository` because nothing about a shift depends on it:
/// the gate, the board and the heartbeat never read a payout, and keeping the
/// two apart means neither fake has to stub the other's endpoints.
abstract class PayoutRepository {
  /// `GET /v1/rider/payouts` — newest week first.
  Future<List<Payout>> payouts();

  /// `GET /v1/rider/payouts/{id}` — one week.
  Future<Payout> payout(String id);
}

class ApiPayoutRepository implements PayoutRepository {
  const ApiPayoutRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Payout>> payouts() async {
    final Map<String, dynamic> response = await _client.get(
      '/v1/rider/payouts',
    );
    final Object? data = response['data'];
    if (data is! List<Object?>) return const <Payout>[];
    return <Payout>[
      for (final Object? raw in data)
        if (raw is Map<String, dynamic>) Payout.fromJson(raw),
    ];
  }

  @override
  Future<Payout> payout(String id) async {
    final Map<String, dynamic> response = await _client.get(
      '/v1/rider/payouts/$id',
    );
    final Object? data = response['data'];
    if (data is Map<String, dynamic>) return Payout.fromJson(data);
    throw const ApiException(
      kind: ApiErrorKind.server,
      message: 'Response did not contain a data object',
    );
  }
}
