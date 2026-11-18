import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/push/push_service.dart';
import '../../core/services/device_setup.dart';
import '../../core/services/preferences_service.dart';

/// A permission the first-run pages ask for, in the order they ask.
///
/// Location first, because it decides whether a rider can go online at all;
/// then the three things that decide whether an order actually reaches them.
enum RiderPermission { location, notifications, battery, fullScreen }

/// What the first-run pages need from the phone, behind one seam so a test
/// can stand in for it.
abstract class PermissionGateway {
  /// The permissions still worth asking for, in [RiderPermission] order.
  ///
  /// Leaves out anything already allowed and anything only Settings can
  /// change, where a prompt would never appear. A check that fails counts as
  /// nothing to ask, so a broken plugin delays nobody.
  Future<List<RiderPermission>> missing();

  /// Shows the system prompt or settings page for [permission]. Returns once
  /// the prompt is answered or the settings page is open.
  Future<void> request(RiderPermission permission);
}

/// The real phone: geolocator, the push transport, and `MainActivity`'s
/// device channel.
class DevicePermissionGateway implements PermissionGateway {
  const DevicePermissionGateway({
    required PushService push,
    DeviceSetup device = const DeviceSetup(),
  })  : _push = push,
        _device = device;

  final PushService _push;
  final DeviceSetup _device;

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<List<RiderPermission>> missing() async {
    final List<RiderPermission> missing = <RiderPermission>[];

    if (await _safe(() async =>
        await Geolocator.checkPermission() == LocationPermission.denied)) {
      missing.add(RiderPermission.location);
    }
    if (await _safe(() async =>
        await _push.notificationAccess() == NotificationAccess.askable)) {
      missing.add(RiderPermission.notifications);
    }
    // Both are Android settings. Off Android, and wherever the channel cannot
    // answer, the device setup reports them as already allowed.
    if (_android && !await _device.isIgnoringBatteryOptimizations()) {
      missing.add(RiderPermission.battery);
    }
    if (_android && !await _device.canUseFullScreenIntent()) {
      missing.add(RiderPermission.fullScreen);
    }
    return missing;
  }

  @override
  Future<void> request(RiderPermission permission) async {
    try {
      switch (permission) {
        case RiderPermission.location:
          await Geolocator.requestPermission();
        case RiderPermission.notifications:
          await _push.requestPermission();
        case RiderPermission.battery:
          await _device.requestIgnoreBatteryOptimizations();
        case RiderPermission.fullScreen:
          await _device.openFullScreenIntentSettings();
      }
    } catch (_) {
      // Whatever went wrong, the rider moves on. The phone setup screen on
      // the board lists anything still missing.
    }
  }

  static Future<bool> _safe(Future<bool> Function() check) async {
    try {
      return await check();
    } catch (_) {
      return false;
    }
  }
}

/// Which first-run pages to show: none once they have been shown, otherwise
/// whatever [PermissionGateway.missing] reports.
///
/// Bounded by [timeout]: the checks take milliseconds on a phone, and a
/// plugin that never answers must not hold a rider on the splash screen. On
/// timeout the pages are skipped, and the phone setup banner covers the rest.
Future<List<RiderPermission>> pendingPermissions({
  required PreferencesService preferences,
  required PermissionGateway gateway,
  Duration timeout = const Duration(seconds: 2),
}) async {
  if (preferences.permissionsAsked) return const <RiderPermission>[];
  try {
    return await gateway.missing().timeout(
          timeout,
          onTimeout: () => const <RiderPermission>[],
        );
  } catch (_) {
    return const <RiderPermission>[];
  }
}
