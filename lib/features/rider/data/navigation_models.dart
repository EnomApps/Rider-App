import 'package:flutter/foundation.dart';

/// Which end of the job the rider is heading to.
enum NavTarget {
  pickup,
  dropoff;

  static NavTarget? fromWire(Object? raw) => switch ('$raw') {
        'pickup' || 'restaurant' => NavTarget.pickup,
        'dropoff' || 'customer' => NavTarget.dropoff,
        _ => null,
      };
}

/// A turn the rider has to make, as Google's routing names it.
///
/// Both the Directions API (`turn-left`) and the Routes API (`TURN_LEFT`)
/// spellings decode here, so the backend can use either without a release.
enum Maneuver {
  straight,
  turnLeft,
  turnRight,
  slightLeft,
  slightRight,
  sharpLeft,
  sharpRight,
  uTurnLeft,
  uTurnRight,
  roundaboutLeft,
  roundaboutRight,
  forkLeft,
  forkRight,
  rampLeft,
  rampRight,
  merge,
  depart,
  arrive;

  static Maneuver fromWire(Object? raw) {
    final String key = '$raw'.toLowerCase().replaceAll('_', '-');
    return switch (key) {
      'turn-left' => Maneuver.turnLeft,
      'turn-right' => Maneuver.turnRight,
      'turn-slight-left' || 'keep-left' => Maneuver.slightLeft,
      'turn-slight-right' || 'keep-right' => Maneuver.slightRight,
      'turn-sharp-left' => Maneuver.sharpLeft,
      'turn-sharp-right' => Maneuver.sharpRight,
      'uturn-left' || 'u-turn-left' => Maneuver.uTurnLeft,
      'uturn-right' || 'u-turn-right' => Maneuver.uTurnRight,
      'roundabout-left' || 'roundabout-counterclockwise' =>
        Maneuver.roundaboutLeft,
      'roundabout-right' || 'roundabout-clockwise' => Maneuver.roundaboutRight,
      'fork-left' => Maneuver.forkLeft,
      'fork-right' => Maneuver.forkRight,
      'ramp-left' => Maneuver.rampLeft,
      'ramp-right' => Maneuver.rampRight,
      'merge' => Maneuver.merge,
      'depart' => Maneuver.depart,
      'arrive' || 'destination' => Maneuver.arrive,
      _ => Maneuver.straight,
    };
  }
}

/// One instruction on the way: "Turn left onto Anna Salai", and where that
/// turn is.
@immutable
class NavStep {
  const NavStep({
    required this.instruction,
    required this.maneuver,
    required this.distanceMetres,
    required this.durationSeconds,
    required this.endLatitude,
    required this.endLongitude,
  });

  /// Plain text in the rider's language. The server strips the HTML the
  /// Directions API wraps around street names.
  final String instruction;

  /// The turn at the *start* of this step. Google puts the maneuver on the
  /// step it begins, which is why the banner shows the next step's maneuver
  /// while the rider is still on the current one.
  final Maneuver maneuver;

  final int distanceMetres;
  final int durationSeconds;

  /// Where this step ends and the next turn is.
  final double endLatitude;
  final double endLongitude;

  static NavStep fromJson(Map<String, dynamic> json) => NavStep(
        instruction: '${json['instruction'] ?? ''}'.trim(),
        maneuver: Maneuver.fromWire(json['maneuver']),
        distanceMetres: _int(json['distance_metres']),
        durationSeconds: _int(json['duration_seconds']),
        endLatitude: _double(json['end_latitude']),
        endLongitude: _double(json['end_longitude']),
      );
}

/// `GET /v1/rider/orders/{order}/route` — the road from where the rider is
/// to where they are going next.
@immutable
class NavRoute {
  const NavRoute({
    required this.target,
    required this.points,
    required this.distanceMetres,
    required this.durationSeconds,
    this.steps = const <NavStep>[],
  });

  final NavTarget target;

  /// The full road, decoded from Google's encoded polyline.
  final List<(double, double)> points;

  final int distanceMetres;
  final int durationSeconds;
  final List<NavStep> steps;

  bool get isUsable => points.length >= 2;

  static NavRoute fromJson(Map<String, dynamic> json, NavTarget fallback) =>
      NavRoute(
        target: NavTarget.fromWire(json['target']) ?? fallback,
        points: decodePolyline('${json['polyline'] ?? ''}'),
        distanceMetres: _int(json['distance_metres']),
        durationSeconds: _int(json['duration_seconds']),
        steps: <NavStep>[
          for (final Object? raw
              in json['steps'] as List<Object?>? ?? const <Object?>[])
            if (raw is Map<String, dynamic>) NavStep.fromJson(raw),
        ],
      );
}

int _int(Object? raw) => switch (raw) {
      final num n => n.round(),
      final String s => (double.tryParse(s) ?? 0).round(),
      _ => 0,
    };

double _double(Object? raw) => switch (raw) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s) ?? 0,
      _ => 0,
    };

/// Decodes a Google encoded polyline into (latitude, longitude) pairs.
///
/// A malformed string decodes to as many points as it got through rather than
/// throwing: half a route is still a direction to ride in.
List<(double, double)> decodePolyline(String encoded) {
  final List<(double, double)> points = <(double, double)>[];
  int index = 0;
  int lat = 0;
  int lng = 0;

  int? next() {
    int result = 0;
    int shift = 0;
    int byte;
    do {
      if (index >= encoded.length) return null;
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  }

  while (index < encoded.length) {
    final int? dLat = next();
    final int? dLng = next();
    if (dLat == null || dLng == null) break;
    lat += dLat;
    lng += dLng;
    points.add((lat / 1e5, lng / 1e5));
  }
  return points;
}
