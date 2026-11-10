import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:nexmile_rider/features/rider/data/location_service.dart';
import 'package:nexmile_rider/features/rider/data/navigation_models.dart';
import 'package:nexmile_rider/features/rider/data/rider_repository.dart';
import 'package:nexmile_rider/features/rider/state/navigation_controller.dart';

/// Answers [route] and nothing else; navigation calls nothing else.
class _RouteRepository implements RiderRepository {
  NavRoute? answer;
  int calls = 0;

  @override
  Future<NavRoute?> route(
    String orderId, {
    required double latitude,
    required double longitude,
    required NavTarget target,
  }) async {
    calls++;
    return answer;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A position the test moves by hand.
class _Location implements LocationService {
  _Location(this.position);

  RiderPosition position;
  LocationDenial? denial;

  void moveTo(double latitude, double longitude) =>
      position = RiderPosition(latitude: latitude, longitude: longitude);

  @override
  Future<void> ensurePermission() async {}

  @override
  Future<RiderPosition> current({bool highAccuracy = false}) async {
    final LocationDenial? refused = denial;
    if (refused != null) throw LocationException(refused);
    return position;
  }

  @override
  Future<void> keepAlive(bool on) async {}
}

// An L-shaped ride in Madurai: north up one street, then east along another.
const double _lng0 = 78.1200;
const double _lat0 = 9.9200;
const double _cornerLat = 9.9300;
const double _endLng = 78.1300;

/// The route as the server would send it, encoded the way Google encodes it.
String _encode(List<(double, double)> points) {
  final StringBuffer out = StringBuffer();
  int lastLat = 0;
  int lastLng = 0;
  void value(int v) {
    int x = v < 0 ? ~(v << 1) : v << 1;
    while (x >= 0x20) {
      out.writeCharCode((0x20 | (x & 0x1f)) + 63);
      x >>= 5;
    }
    out.writeCharCode(x + 63);
  }

  for (final (double lat, double lng) in points) {
    final int la = (lat * 1e5).round();
    final int ln = (lng * 1e5).round();
    value(la - lastLat);
    value(ln - lastLng);
    lastLat = la;
    lastLng = ln;
  }
  return out.toString();
}

NavRoute _lRoute() => NavRoute.fromJson(<String, dynamic>{
      'target': 'dropoff',
      'polyline': _encode(const <(double, double)>[
        (_lat0, _lng0),
        (_cornerLat, _lng0),
        (_cornerLat, _endLng),
      ]),
      'distance_metres': 2208,
      'duration_seconds': 480,
      'steps': <Map<String, dynamic>>[
        <String, dynamic>{
          'instruction': 'Head north on Anna Nagar Main Road',
          'maneuver': 'depart',
          'distance_metres': 1112,
          'duration_seconds': 240,
          'end_latitude': _cornerLat,
          'end_longitude': _lng0,
        },
        <String, dynamic>{
          'instruction': 'Turn right onto 3rd Street',
          'maneuver': 'TURN_RIGHT',
          'distance_metres': 1096,
          'duration_seconds': 240,
          'end_latitude': _cornerLat,
          'end_longitude': _endLng,
        },
      ],
    }, NavTarget.dropoff);

void main() {
  late _RouteRepository repository;
  late _Location location;
  late NavigationController nav;

  NavigationController build({Duration cooldown = Duration.zero}) =>
      NavigationController(
        repository: repository,
        location: location,
        orderId: '1001',
        target: NavTarget.dropoff,
        destination: const LatLng(_cornerLat, _endLng),
        // Long enough that the periodic timer never fires mid-test; each
        // test drives reads by hand through [_tick].
        tick: const Duration(hours: 1),
        rerouteCooldown: cooldown,
      );

  Future<void> tick() async {
    nav.stop();
    nav.start();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    repository = _RouteRepository()..answer = _lRoute();
    location = _Location(const RiderPosition(latitude: _lat0, longitude: _lng0));
    nav = build();
  });

  tearDown(() => nav.dispose());

  test('decodes both maneuver spellings', () {
    expect(Maneuver.fromWire('turn-right'), Maneuver.turnRight);
    expect(Maneuver.fromWire('TURN_RIGHT'), Maneuver.turnRight);
    expect(Maneuver.fromWire('ROUNDABOUT_CLOCKWISE'), Maneuver.roundaboutRight);
    expect(Maneuver.fromWire('something-new'), Maneuver.straight);
  });

  test('at the start, the next turn is the right at the corner', () async {
    await tick();

    expect(repository.calls, 1);
    expect(nav.path, isNotNull);
    expect(nav.nextTurn?.maneuver, Maneuver.turnRight);
    expect(nav.distanceToTurn, closeTo(1112, 10));
    expect(nav.remainingMetres, closeTo(2208, 15));
    // The whole route still ahead, so the whole estimate.
    expect(nav.remainingTime!.inSeconds, closeTo(480, 5));
  });

  test('the turn counts down as the rider rides up the street', () async {
    await tick();
    location.moveTo(9.9250, _lng0);
    await tick();

    expect(nav.distanceToTurn, closeTo(556, 10));
    expect(nav.remainingTime!.inSeconds, lessThan(480));
  });

  test('after the corner, no turns remain and the stop is ahead', () async {
    await tick();
    location.moveTo(_cornerLat, 78.1250);
    await tick();

    expect(nav.nextTurn, isNull);
    expect(nav.distanceToTurn, closeTo(548, 10));
  });

  test('one wild fix is ignored; two off the route reroute', () async {
    await tick();
    expect(repository.calls, 1);

    // 200 m west of the street.
    location.moveTo(9.9250, 78.1182);
    await tick();
    expect(repository.calls, 1, reason: 'one fix could be GPS noise');

    await tick();
    expect(repository.calls, 2, reason: 'two in a row is a wrong turn');
  });

  test('reroutes wait out the cooldown', () async {
    nav.dispose();
    nav = build(cooldown: const Duration(minutes: 5));
    await tick();

    location.moveTo(9.9250, 78.1182);
    await tick();
    await tick();
    await tick();

    // Off the route for three fixes, but the first route was moments ago.
    expect(repository.calls, 1);
  });

  test('without a route it still gives a distance to the stop', () async {
    repository.answer = null;
    await tick();

    expect(nav.routeUnavailable, isTrue);
    expect(nav.path, isNull);
    expect(nav.remainingMetres, greaterThan(1500));
    // A straight line has no honest duration.
    expect(nav.remainingTime, isNull);
  });

  test('within 40 m of the stop is arrival', () async {
    await tick();
    location.moveTo(_cornerLat, _endLng - 0.0002);
    await tick();

    expect(nav.hasArrived, isTrue);
  });

  test('a refused location is reported, not swallowed', () async {
    location.denial = LocationDenial.serviceDisabled;
    await tick();

    expect(nav.locationDenial, LocationDenial.serviceDisabled);
    expect(repository.calls, 0);
  });
}
