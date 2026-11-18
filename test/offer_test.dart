import 'package:flutter_test/flutter_test.dart';
import 'package:nexmile_rider/core/network/api_exception.dart';
import 'package:nexmile_rider/features/rider/data/offer_models.dart';
import 'package:nexmile_rider/features/rider/data/order_models.dart';
import 'package:nexmile_rider/features/rider/data/rider_repository.dart';
import 'package:nexmile_rider/features/rider/state/offer_controller.dart';

/// Answers the offer endpoints and nothing else.
class _OfferRepository implements RiderRepository {
  OrderOffer? live;
  Object? acceptError;
  int accepts = 0;
  int rejects = 0;
  String? rejectReason;

  @override
  Future<OrderOffer?> currentOffer() async => live;

  @override
  Future<RiderOrder> acceptOffer(String offerId) async {
    accepts++;
    final Object? error = acceptError;
    if (error != null) throw error;
    return RiderOrder.fromJson(<String, dynamic>{
      'id': '41',
      'order_number': 'NX261113ABCD',
      'status': 'rider_assigned',
      'pickup': <String, dynamic>{'address': 'Ponnusamy Hotel'},
      'dropoff': <String, dynamic>{
        'contact_name': 'Anand',
        'contact_phone': '9876500011',
        'address': '12 Anna Nagar',
        'line1': 'Flat 3B, 2nd floor',
        'line2': 'Gandhi Street',
        'landmark': 'Near the water tank',
        'photo_url': 'https://cdn.example/addresses/12/photo.jpg',
      },
    });
  }

  @override
  Future<void> rejectOffer(String offerId, {String? reason}) async {
    rejects++;
    rejectReason = reason;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Counts rings and silences.
class _Alert implements OfferAlert {
  int rings = 0;
  int silences = 0;

  @override
  Future<void> ring(OrderOffer offer) async => rings++;

  @override
  Future<void> silence(OrderOffer offer) async => silences++;
}

final DateTime _now = DateTime.utc(2026, 11, 13, 18, 42, 1);

/// The payload exactly as FCM delivers it: every value a string.
Map<String, Object?> _push({
  String offerId = '01JCQ2W8XK3N4P5Q6R7S8T9V0W',
  String orderId = '41',
  DateTime? expiresAt,
  String secondsLeft = '30',
}) =>
    <String, Object?>{
      'type': 'ORDER_OFFER',
      'offer_id': offerId,
      'order_id': orderId,
      'order_number': 'NX261113ABCD',
      'expires_at': (expiresAt ?? _now.add(const Duration(seconds: 30)))
          .toIso8601String(),
      'seconds_left': secondsLeft,
      'restaurant': 'Ponnusamy Hotel',
      'restaurant_area': 'Madurai',
      'pickup_distance_metres': '240',
      'dropoff_area': 'Madurai',
      'delivery_distance_metres': '620',
      'item_count': '3',
      'earnings': '34.50',
      'collect_cash': '430.00',
      'wave': '1',
    };

void main() {
  group('offer payload', () {
    test('parses the all-strings FCM shape', () {
      final OrderOffer offer = OrderOffer.fromData(_push(), receivedAt: _now)!;

      expect(offer.orderId, '41');
      expect(offer.restaurant, 'Ponnusamy Hotel');
      expect(offer.pickupDistanceMetres, 240);
      expect(offer.itemCount, 3);
      expect(offer.earnings, 34.5);
      expect(offer.collectCash, 430);
      expect(offer.remaining(_now).inSeconds, 30);
    });

    test('counts to expires_at, the server\'s deadline', () {
      // Two seconds of delivery delay: the window is 28 s, not 30.
      final OrderOffer offer = OrderOffer.fromData(
        _push(expiresAt: _now.add(const Duration(seconds: 28))),
        receivedAt: _now,
      )!;
      expect(offer.remaining(_now).inSeconds, 28);
    });

    test('a phone with a wrong clock falls back to seconds_left', () {
      // The phone is ten minutes fast, so expires_at looks long past.
      final OrderOffer offer = OrderOffer.fromData(
        _push(expiresAt: _now.subtract(const Duration(minutes: 10))),
        receivedAt: _now,
      )!;
      expect(offer.remaining(_now).inSeconds, 30);
    });

    test('a payload with no ids is not an offer', () {
      expect(OrderOffer.fromData(<String, Object?>{'type': 'ORDER_OFFER'}), isNull);
    });
  });

  group('offer controller', () {
    late _OfferRepository repository;
    late _Alert alert;
    late DateTime clock;
    late OfferController offers;

    setUp(() {
      repository = _OfferRepository();
      alert = _Alert();
      clock = _now;
      offers = OfferController(
        repository: repository,
        alert: alert,
        clock: () => clock,
      );
    });

    tearDown(() => offers.dispose());

    test('an offer push puts up a card and rings', () {
      offers.handleMessage(_push());

      expect(offers.offer?.orderId, '41');
      expect(alert.rings, 1);
    });

    test('the same offer twice is one card, one ring', () {
      offers.handleMessage(_push());
      offers.handleMessage(_push());

      expect(alert.rings, 1);
    });

    test('a second offer never replaces a live card', () {
      offers.handleMessage(_push());
      offers.handleMessage(_push(offerId: 'other', orderId: '42'));

      expect(offers.offer?.orderId, '41');
    });

    test('a push that lands after its window shows nothing', () {
      offers.handleMessage(
        _push(
          expiresAt: _now.subtract(const Duration(seconds: 1)),
          secondsLeft: '0',
        ),
      );
      expect(offers.offer, isNull);
    });

    test('a withdrawal dismisses by order id and stops the ring', () {
      offers.handleMessage(_push());
      offers.handleMessage(<String, Object?>{
        'type': 'OFFER_CANCELLED',
        'order_id': '41',
        'reason': 'taken',
      });

      expect(offers.offer, isNull);
      expect(alert.silences, 1);
    });

    test('a withdrawal for another order leaves the card alone', () {
      offers.handleMessage(_push());
      offers.withdraw('99');
      expect(offers.offer, isNotNull);
    });

    test('auto-offline is reported so duty can flip off', () {
      offers.handleMessage(_push());
      final bool offline = offers.handleMessage(
        <String, Object?>{'type': 'rider.auto_offline'},
      );

      expect(offline, isTrue);
      expect(offers.offer, isNull);
    });

    test('200 wins the order with its drop address', () async {
      offers.handleMessage(_push());
      final AcceptOutcome outcome = await offers.accept();

      expect(outcome, isA<OfferWon>());
      expect((outcome as OfferWon).order.dropoff?.address, '12 Anna Nagar');
      // The accept answer is the full order: the door arrives with it.
      expect(outcome.order.dropoff?.line1, 'Flat 3B, 2nd floor');
      expect(outcome.order.dropoff?.line2, 'Gandhi Street');
      expect(outcome.order.dropoff?.landmark, 'Near the water tank');
      expect(
        outcome.order.dropoff?.photoUrl,
        'https://cdn.example/addresses/12/photo.jpg',
      );
      expect(offers.offer, isNull);
      expect(alert.silences, 1);
    });

    test('409 reads as taken by another rider', () async {
      repository.acceptError =
          const ApiException(kind: ApiErrorKind.server, statusCode: 409);
      offers.handleMessage(_push());

      expect(await offers.accept(), isA<OfferTaken>());
      expect(offers.offer, isNull);
    });

    test('410 closes the card silently', () async {
      repository.acceptError =
          const ApiException(kind: ApiErrorKind.server, statusCode: 410);
      offers.handleMessage(_push());

      expect(await offers.accept(), isA<OfferGone>());
    });

    test('422 carries the server reason', () async {
      repository.acceptError = const ApiException(
        kind: ApiErrorKind.validation,
        statusCode: 422,
        errors: <String, List<String>>{
          'rider': <String>['Finish your current delivery first'],
        },
      );
      offers.handleMessage(_push());

      final AcceptOutcome outcome = await offers.accept();
      expect((outcome as OfferRefused).message,
          'Finish your current delivery first');
    });

    test('a dropped connection keeps the card up to try again', () async {
      repository.acceptError =
          const ApiException(kind: ApiErrorKind.network);
      offers.handleMessage(_push());

      expect(await offers.accept(), isA<OfferRetry>());
      expect(offers.offer, isNotNull);
    });

    test('declining closes at once and sends the reason', () async {
      offers.handleMessage(_push());
      await offers.reject(reason: 'Too far');

      expect(offers.offer, isNull);
      expect(repository.rejects, 1);
      expect(repository.rejectReason, 'Too far');
    });

    test('sync shows the live card even after the push showed it', () async {
      offers.handleMessage(_push());
      await offers.reject();
      repository.live = OrderOffer.fromData(_push(), receivedAt: _now);

      await offers.sync();
      expect(offers.offer, isNotNull);
    });

    test('sync clears a card the server no longer has', () async {
      offers.handleMessage(_push());
      repository.live = null;

      await offers.sync();
      expect(offers.offer, isNull);
      expect(alert.silences, 1);
    });
  });
}
