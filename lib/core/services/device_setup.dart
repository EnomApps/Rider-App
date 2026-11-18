import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The phone settings an order alert depends on, from `MainActivity`'s
/// `nexmile/device` channel.
///
/// Every call is safe anywhere: off Android, in a test, or on a build without
/// the channel, each answers the harmless default ("allowed", "nothing to
/// do") rather than throwing, so a missing setting can never crash a shift.
class DeviceSetup {
  const DeviceSetup();

  static const MethodChannel _channel = MethodChannel('nexmile/device');

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  Future<T> _call<T>(String method, T fallback, [Object? argument]) async {
    if (!_android) return fallback;
    try {
      return await _channel.invokeMethod<T>(method, argument) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  /// Shows the app over the lock screen and wakes the display. On only while
  /// an offer card is up.
  Future<void> showOverLockScreen(bool on) =>
      _call<void>('showOverLockScreen', null, on);

  /// Switches the display on for a moment if it is off. For a new order that
  /// arrives while the phone is locked and dark.
  Future<void> wakeScreen() => _call<void>('wakeScreen', null);

  Future<bool> canUseFullScreenIntent() =>
      _call<bool>('canUseFullScreenIntent', true);

  Future<void> openFullScreenIntentSettings() =>
      _call<void>('openFullScreenIntentSettings', null);

  Future<bool> isIgnoringBatteryOptimizations() =>
      _call<bool>('isIgnoringBatteryOptimizations', true);

  Future<void> requestIgnoreBatteryOptimizations() =>
      _call<void>('requestIgnoreBatteryOptimizations', null);

  Future<void> openAppSettings() => _call<void>('openAppSettings', null);

  Future<String> manufacturer() => _call<String>('manufacturer', '');
}
