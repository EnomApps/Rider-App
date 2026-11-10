import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../data/location_service.dart';
import '../data/navigation_models.dart';
import '../data/rider_repository.dart';
import '../presentation/navigation/route_geometry.dart';

/// Turn-by-turn state for one leg of a delivery: to the restaurant, or to the
/// customer.
///
/// Reads the rider's position every couple of seconds and works out, against
/// the route the server sent, which step they are on, how far the next turn
/// is, and how much is left. The server routes; this only measures. When the
/// rider leaves the route it asks for a new one, the way a sat-nav does.
class NavigationController extends ChangeNotifier {
  NavigationController({
    required RiderRepository repository,
    required LocationService location,
    required this.orderId,
    required this.target,
    required this.destination,
    this.tick = const Duration(seconds: 2),
    this.rerouteCooldown = const Duration(seconds: 15),
  })  : _repository = repository,
        _location = location;

  final RiderRepository _repository;
  final LocationService _location;

  final String orderId;
  final NavTarget target;
  final LatLng destination;

  /// How often the position is read. While an order is in hand the location
  /// stream is already running, so each read is the latest streamed fix and
  /// costs nothing.
  final Duration tick;

  /// Within this of the stop counts as there. Wider than GPS noise, tighter
  /// than a street.
  static const double arrivalMetres = 40;

  /// Further than this from the route, twice in a row, is a wrong turn.
  static const double offRouteMetres = 45;

  /// Never ask for a new route more often than this: a rider weaving through
  /// a market should not cost a Directions call every two seconds.
  final Duration rerouteCooldown;

  Timer? _timer;
  bool _reading = false;
  bool _disposed = false;

  RiderPosition? _position;
  NavRoute? _route;
  RoutePath? _path;

  /// How far along [_path] each step ends, in metres.
  List<double> _stepEnds = const <double>[];

  double _along = 0;
  int _stepIndex = 0;
  int _offRouteStrikes = 0;
  DateTime? _lastRouteAt;
  bool _isRouting = false;
  bool _routeUnavailable = false;
  bool _arrived = false;
  LocationDenial? _denial;

  RiderPosition? get position => _position;
  LatLng? get here => _position == null
      ? null
      : LatLng(_position!.latitude, _position!.longitude);

  NavRoute? get route => _route;
  RoutePath? get path => _path;

  /// True while the first route, or a reroute, is being fetched.
  bool get isRouting => _isRouting;

  /// The server could not route. The screen shows a straight line and a
  /// distance instead of turns.
  bool get routeUnavailable => _routeUnavailable;

  bool get hasArrived => _arrived;
  LocationDenial? get locationDenial => _denial;

  /// The step the rider is on now.
  NavStep? get currentStep {
    final List<NavStep> steps = _route?.steps ?? const <NavStep>[];
    return _stepIndex < steps.length ? steps[_stepIndex] : null;
  }

  /// The next turn, which is what the banner leads with. Google hangs each
  /// maneuver on the step it starts, so the turn ahead belongs to the step
  /// after this one.
  NavStep? get nextTurn {
    final List<NavStep> steps = _route?.steps ?? const <NavStep>[];
    return _stepIndex + 1 < steps.length ? steps[_stepIndex + 1] : null;
  }

  /// The turn after that, for the "Then …" line.
  NavStep? get turnAfter {
    final List<NavStep> steps = _route?.steps ?? const <NavStep>[];
    return _stepIndex + 2 < steps.length ? steps[_stepIndex + 2] : null;
  }

  /// Metres to the next turn, or to the stop when there are no turns left.
  double? get distanceToTurn {
    final RoutePath? path = _path;
    if (path == null) return remainingMetres;
    if (_stepIndex < _stepEnds.length) {
      return (_stepEnds[_stepIndex] - _along).clamp(0, double.infinity);
    }
    return remainingMetres;
  }

  /// Road distance left, or the straight line when there is no road.
  double? get remainingMetres {
    final LatLng? from = here;
    if (from == null) return null;
    final RoutePath? path = _path;
    if (path != null) return (path.length - _along).clamp(0, double.infinity);
    return distanceMetres(from, destination);
  }

  /// Time left, scaled from the server's estimate by the share of road still
  /// ahead. Null without a route: a straight line has no honest duration.
  Duration? get remainingTime {
    final NavRoute? route = _route;
    final RoutePath? path = _path;
    final double? left = remainingMetres;
    if (route == null || path == null || left == null || path.length == 0) {
      return null;
    }
    final double share = left / path.length;
    return Duration(seconds: (route.durationSeconds * share).round());
  }

  /// Metres along the route the rider has reached, for trimming the line.
  double get along => _along;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(tick, (_) => unawaited(_read()));
    unawaited(_read());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _read() async {
    if (_reading) return;
    _reading = true;
    try {
      final RiderPosition position =
          await _location.current(highAccuracy: true);
      _denial = null;
      _position = position;
      await _onPosition(position);
    } on LocationException catch (error) {
      _denial = error.denial;
    } catch (_) {
      // A missed fix; the next tick tries again.
    } finally {
      _reading = false;
      _notify();
    }
  }

  Future<void> _onPosition(RiderPosition position) async {
    final LatLng p = LatLng(position.latitude, position.longitude);

    if (distanceMetres(p, destination) <= arrivalMetres) {
      _arrived = true;
      return;
    }
    _arrived = false;

    final RoutePath? path = _path;
    if (path == null) {
      if (!_routeUnavailable || _cooledDown()) await _fetchRoute(p);
      return;
    }

    final RouteFix fix = path.project(p);
    if (fix.offRouteMetres > offRouteMetres) {
      _offRouteStrikes++;
      // Two strikes, so one wild GPS fix under a flyover does not reroute.
      if (_offRouteStrikes >= 2 && _cooledDown()) await _fetchRoute(p);
      return;
    }
    _offRouteStrikes = 0;

    // Never backwards along the route: a fix that lands a few metres behind
    // the last one is noise, and the banner counting up would read as wrong.
    if (fix.along > _along) _along = fix.along;
    _advanceStep();
  }

  bool _cooledDown() {
    final DateTime? last = _lastRouteAt;
    return last == null || DateTime.now().difference(last) >= rerouteCooldown;
  }

  Future<void> _fetchRoute(LatLng from) async {
    if (_isRouting) return;
    _isRouting = true;
    _lastRouteAt = DateTime.now();
    _notify();

    try {
      final NavRoute? route = await _repository.route(
        orderId,
        latitude: from.latitude,
        longitude: from.longitude,
        target: target,
      );
      if (route == null) {
        _routeUnavailable = true;
        _route = null;
        _path = null;
        _stepEnds = const <double>[];
        return;
      }
      _routeUnavailable = false;
      _setRoute(route, from);
    } catch (_) {
      // Network trouble. Keep whatever route there was; the next strike or
      // tick asks again once the cooldown passes.
    } finally {
      _isRouting = false;
      _offRouteStrikes = 0;
    }
  }

  void _setRoute(NavRoute route, LatLng from) {
    final RoutePath path = RoutePath(<LatLng>[
      for (final (double lat, double lng) in route.points) LatLng(lat, lng),
    ]);
    _route = route;
    _path = path;

    // Each step's end, measured along the road. Kept non-decreasing, because
    // a step end that projects a metre behind the previous one would make the
    // step counter go backwards.
    double last = 0;
    _stepEnds = <double>[
      for (final NavStep step in route.steps)
        () {
          final double end = path
              .project(LatLng(step.endLatitude, step.endLongitude))
              .along;
          last = end > last ? end : last;
          return last;
        }(),
    ];

    _along = path.project(from).along;
    _stepIndex = 0;
    _advanceStep();
  }

  void _advanceStep() {
    // A step counts as done a few metres before its end, so the banner moves
    // on to the next turn as the rider is taking this one, not after.
    while (_stepIndex < _stepEnds.length - 1 &&
        _along >= _stepEnds[_stepIndex] - 8) {
      _stepIndex++;
    }
  }
}
