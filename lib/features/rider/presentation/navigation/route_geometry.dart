import 'dart:math' as math;

import 'package:latlong2/latlong.dart' show LatLng;

/// Geometry for the navigation map, kept free of any map plugin so it can be
/// tested on its own. The same maths the customer app uses to draw this ride.
///
/// Distances are metres on a sphere. At delivery scale (a few kilometres) the
/// error against the true ellipsoid is well under a metre, far below GPS noise.
const double _earthRadius = 6371008.8;

double _rad(double degrees) => degrees * math.pi / 180;
double _deg(double radians) => radians * 180 / math.pi;

/// Great-circle distance between two points, in metres.
double distanceMetres(LatLng a, LatLng b) {
  final double dLat = _rad(b.latitude - a.latitude);
  final double dLng = _rad(b.longitude - a.longitude);
  final double h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.latitude)) *
          math.cos(_rad(b.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadius * math.asin(math.min(1, math.sqrt(h)));
}

/// Initial compass bearing from [a] to [b], 0-360 clockwise from north.
double bearingDegrees(LatLng a, LatLng b) {
  final double lat1 = _rad(a.latitude);
  final double lat2 = _rad(b.latitude);
  final double dLng = _rad(b.longitude - a.longitude);
  final double y = math.sin(dLng) * math.cos(lat2);
  final double x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (_deg(math.atan2(y, x)) + 360) % 360;
}

/// Straight-line interpolation. Over the tens of metres a rider covers between
/// fixes, the difference from a great-circle path is invisible.
LatLng lerpLatLng(LatLng a, LatLng b, double t) => LatLng(
  a.latitude + (b.latitude - a.latitude) * t,
  a.longitude + (b.longitude - a.longitude) * t,
);

/// Turns from [from] to [to] the short way round, so a rider heading 350°
/// who turns to 10° rotates 20° clockwise rather than 340° back.
double lerpBearing(double from, double to, double t) {
  final double delta = ((to - from + 540) % 360) - 180;
  return (from + delta * t + 360) % 360;
}

/// A curved line from [a] to [b], bowed to one side like the arc Swiggy draws
/// before a route is known. A straight line between two pins reads as a road
/// through the buildings; a curve reads as "about this way".
List<LatLng> arcBetween(LatLng a, LatLng b, {int segments = 32}) {
  final double distance = distanceMetres(a, b);
  if (distance < 1) return <LatLng>[a, b];

  // The control point sits off the midpoint, perpendicular to the chord, at a
  // fifth of its length. Enough to read as a curve without looping.
  final LatLng mid = lerpLatLng(a, b, 0.5);
  final double dLat = b.latitude - a.latitude;
  final double dLng = b.longitude - a.longitude;
  final LatLng control = LatLng(
    mid.latitude - dLng * 0.2,
    mid.longitude + dLat * 0.2,
  );

  return <LatLng>[
    for (int i = 0; i <= segments; i++)
      () {
        final double t = i / segments;
        final double u = 1 - t;
        return LatLng(
          u * u * a.latitude +
              2 * u * t * control.latitude +
              t * t * b.latitude,
          u * u * a.longitude +
              2 * u * t * control.longitude +
              t * t * b.longitude,
        );
      }(),
  ];
}

/// Where a point falls on a [RoutePath].
class RouteFix {
  const RouteFix({required this.along, required this.offRouteMetres});

  /// Metres from the start of the route to the nearest point on it.
  final double along;

  /// How far the point itself is from that nearest point.
  final double offRouteMetres;
}

/// A polyline measured along its length, so a marker can be placed "340 m
/// into the route" and the line can be trimmed behind it.
class RoutePath {
  RoutePath(List<LatLng> points)
    : points = List<LatLng>.unmodifiable(points),
      _cumulative = _measure(points);

  final List<LatLng> points;
  final List<double> _cumulative;

  double get length => _cumulative.isEmpty ? 0 : _cumulative.last;
  bool get isUsable => points.length >= 2 && length > 0;

  static List<double> _measure(List<LatLng> points) {
    final List<double> out = <double>[];
    double total = 0;
    for (int i = 0; i < points.length; i++) {
      if (i > 0) total += distanceMetres(points[i - 1], points[i]);
      out.add(total);
    }
    return out;
  }

  /// The nearest point on the route to [p].
  ///
  /// Projects onto each segment in a local flat frame centred on [p]; at this
  /// scale that is accurate to centimetres and an order of magnitude cheaper
  /// than doing it on the sphere.
  RouteFix project(LatLng p) {
    final double cosLat = math.cos(_rad(p.latitude));
    double bestAlong = 0;
    double bestDistance = double.infinity;

    for (int i = 0; i < points.length - 1; i++) {
      final LatLng a = points[i];
      final LatLng b = points[i + 1];
      final double ax = (a.longitude - p.longitude) * cosLat;
      final double ay = a.latitude - p.latitude;
      final double bx = (b.longitude - p.longitude) * cosLat;
      final double by = b.latitude - p.latitude;
      final double dx = bx - ax;
      final double dy = by - ay;
      final double len2 = dx * dx + dy * dy;
      final double t =
          len2 == 0 ? 0 : (-(ax * dx + ay * dy) / len2).clamp(0.0, 1.0);
      final LatLng nearest = lerpLatLng(a, b, t);
      final double d = distanceMetres(p, nearest);
      if (d < bestDistance) {
        bestDistance = d;
        bestAlong = _cumulative[i] + (_cumulative[i + 1] - _cumulative[i]) * t;
      }
    }
    return RouteFix(along: bestAlong, offRouteMetres: bestDistance);
  }

  int _segmentAt(double along) {
    // Binary search: routes from Directions run to hundreds of points and this
    // is called every animation frame.
    int lo = 0;
    int hi = _cumulative.length - 1;
    while (lo < hi - 1) {
      final int mid = (lo + hi) >> 1;
      if (_cumulative[mid] <= along) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  LatLng pointAt(double along) {
    if (points.length < 2) return points.first;
    final double d = along.clamp(0.0, length);
    final int i = _segmentAt(d);
    final double span = _cumulative[i + 1] - _cumulative[i];
    final double t = span == 0 ? 0 : (d - _cumulative[i]) / span;
    return lerpLatLng(points[i], points[i + 1], t);
  }

  /// Direction of travel at [along].
  double bearingAt(double along) {
    final int i = _segmentAt(along.clamp(0.0, length));
    return bearingDegrees(points[i], points[i + 1]);
  }

  /// The route from [from] metres to [to] metres, endpoints included.
  List<LatLng> slice(double from, double to) {
    final double start = from.clamp(0.0, length);
    final double end = to.clamp(start, length);
    final List<LatLng> out = <LatLng>[pointAt(start)];
    for (int i = 0; i < points.length; i++) {
      if (_cumulative[i] > start && _cumulative[i] < end) out.add(points[i]);
    }
    out.add(pointAt(end));
    return out;
  }
}
