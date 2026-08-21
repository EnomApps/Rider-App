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
  });

  final double latitude;
  final double longitude;
  final double? accuracyMetres;
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
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

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
      return RiderPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMetres: position.accuracy,
      );
    } on LocationException {
      rethrow;
    } catch (_) {
      // A timeout indoors, or a platform refusal this build does not model.
      // Either way the rider can do nothing but wait for a better sky.
      throw const LocationException(LocationDenial.unavailable);
    }
  }
}
