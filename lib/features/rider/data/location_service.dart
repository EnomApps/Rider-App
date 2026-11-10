import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// A position, decoupled from the plugin that produced it.
///
/// Kept as its own type so the controller and its tests never import
/// `geolocator` — a fake service returning fixed coordinates is what makes the
/// dispatch flow testable without a device that can actually move.
class RiderPosition {
  const RiderPosition({
    required this.latitude,
    required this.longitude,
    this.accuracyMetres,
    this.headingDegrees,
    this.speedMetresPerSecond,
    this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMetres;

  /// Direction of travel, 0-360 clockwise from north. Null when the device
  /// could not tell, which is most of the time a rider is standing still.
  final double? headingDegrees;

  final double? speedMetresPerSecond;

  /// When the phone took the fix. The server orders pings by this, so a
  /// burst that arrives late after a basement still lands in sequence.
  final DateTime? recordedAt;
}

/// Why a fix could not be taken.
///
/// Split by what the rider can do about it, not by what the platform called
/// it: [permissionDenied] is a prompt away, [permissionDeniedForever] needs
/// the system settings, [serviceDisabled] needs the GPS switch, and
/// [unavailable] is a timeout or a device with no fix indoors.
enum LocationDenial {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  unavailable,
}

class LocationException implements Exception {
  const LocationException(this.denial);

  final LocationDenial denial;

  @override
  String toString() => 'LocationException(${denial.name})';
}

/// Opens whichever settings screen can undo [denial].
///
/// Two different destinations, because the two refusals live in different
/// places: a permission the rider denied permanently is in the app's own
/// settings, while location switched off entirely is a system toggle. Sending
/// someone to the wrong one is worse than sending them nowhere.
Future<void> openLocationSettings(LocationDenial denial) async {
  if (denial == LocationDenial.serviceDisabled) {
    await Geolocator.openLocationSettings();
    return;
  }
  await Geolocator.openAppSettings();
}

/// The device's position, for the dispatch heartbeat.
abstract class LocationService {
  /// Asks for permission if it has not been granted. Returns normally when the
  /// app may read a position, throws [LocationException] otherwise.
  Future<void> ensurePermission();

  /// One fix. Throws [LocationException] if permission or the service is
  /// missing.
  Future<RiderPosition> current({bool highAccuracy = false});

  /// Keeps location running with the screen locked, while [on].
  ///
  /// On for as long as an order is in hand. Without it Android stops the app
  /// the moment the rider pockets the phone, and the customer's map freezes
  /// at the restaurant. Android shows an ongoing notification for as long as
  /// it is on; iOS shows the blue location pill.
  Future<void> keepAlive(bool on);
}

class GeolocatorLocationService implements LocationService {
  GeolocatorLocationService();

  /// The background stream, while [keepAlive] is on.
  StreamSubscription<Position>? _stream;
  Position? _latest;

  /// How old a streamed fix may be and still answer [current]. Longer than
  /// the active heartbeat so a rider at a red light, whose stream has gone
  /// quiet under the distance filter, still gets a fix without waking GPS.
  static const Duration _freshFor = Duration(seconds: 20);

  @override
  Future<void> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationDenial.serviceDisabled);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.denied:
        throw const LocationException(LocationDenial.permissionDenied);
      case LocationPermission.deniedForever:
        throw const LocationException(LocationDenial.permissionDeniedForever);
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return;
      case LocationPermission.unableToDetermine:
        // Android returns this when the platform channel cannot answer. Treat
        // it as a soft failure: the fix itself will throw properly if there is
        // really no permission, and refusing here would block a rider whose
        // device simply answered slowly.
        return;
    }
  }

  @override
  Future<RiderPosition> current({bool highAccuracy = false}) async {
    final Position? latest = _latest;
    if (_stream != null &&
        latest != null &&
        DateTime.now().difference(latest.timestamp) < _freshFor) {
      return _toRider(latest);
    }

    await ensurePermission();

    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          // Battery, deliberately: a rider idling on the board only needs to
          // be in the right part of town for dispatch to rank restaurants by
          // distance, while one carrying an order is being watched by a
          // customer and has to be where the map says.
          accuracy:
              highAccuracy ? LocationAccuracy.best : LocationAccuracy.medium,
          // A fix that has not landed inside this is not worth waiting on —
          // the next tick of the heartbeat is closer than the retry would be.
          timeLimit: const Duration(seconds: 20),
        ),
      );
      return _toRider(position);
    } on LocationException {
      rethrow;
    } catch (_) {
      // A timeout indoors, or a platform refusal this build does not model.
      // Either way the rider can do nothing but wait for a better sky.
      throw const LocationException(LocationDenial.unavailable);
    }
  }

  @override
  Future<void> keepAlive(bool on) async {
    if (!on) {
      await _stream?.cancel();
      _stream = null;
      _latest = null;
      return;
    }
    if (_stream != null) return;

    await ensurePermission();
    _stream = Geolocator.getPositionStream(locationSettings: _backgroundSettings())
        .listen(
      (Position position) => _latest = position,
      // A stream that errors mid-delivery leaves the heartbeat to fall back on
      // one-off fixes, which still work while the app is in the foreground.
      onError: (Object _) {},
    );
  }

  static LocationSettings _backgroundSettings() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10,
          intervalDuration: const Duration(seconds: 5),
          // The foreground service is what keeps the process alive once the
          // screen locks. Android insists it be visible, so it is honest
          // about what it is doing.
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Delivering an order',
            notificationText:
                'Sharing your location with the customer until delivery.',
            enableWakeLock: true,
            setOngoing: true,
          ),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.best,
          activityType: ActivityType.automotiveNavigation,
          distanceFilter: 10,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10,
        );
    }
  }

  static RiderPosition _toRider(Position position) => RiderPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMetres: position.accuracy,
        // Geolocator reports -1 or 0 when it has no bearing; a rider who is
        // not moving has no meaningful direction either.
        headingDegrees: position.heading >= 0 && position.speed > 0.5
            ? position.heading
            : null,
        speedMetresPerSecond: position.speed >= 0 ? position.speed : null,
        recordedAt: position.timestamp,
      );
}
