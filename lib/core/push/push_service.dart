import 'dart:async';

import 'package:flutter/foundation.dart';

/// The Android notification channel the server posts order notifications to.
///
/// It has to exist before the first notification arrives, and a mismatch is
/// *silent* — Android drops the notification without a log line — so the id
/// lives in exactly one place and is created on first run rather than on
/// sign-in.
const String kOrdersChannelId = 'nexmile_orders';

/// The push transport, behind an interface.
///
/// Everything above this line — registering the device, routing a tap — is
/// ordinary Dart that runs in a test. Only the implementation of this talks to
/// Firebase, which is the one part that needs a `google-services.json` and a
/// real device to prove.
abstract class PushService {
  /// The current registration token, or null when push is unavailable —
  /// permission refused, no Play Services, or a build with no Firebase in it.
  Future<String?> token();

  /// Fires when the transport rotates the token. A rotated token that is not
  /// re-registered means notifications stop arriving, silently, forever.
  Stream<String> get onTokenRefresh;

  /// Notification taps, including the one that launched the app from cold.
  Stream<Map<String, Object?>> get onTap;

  /// Asks the rider. Returns false when they say no — which is a normal
  /// outcome, not an error.
  Future<bool> requestPermission();

  /// Creates [kOrdersChannelId] on Android. A no-op elsewhere.
  Future<void> ensureChannel();
}

/// What the app runs with until Firebase is wired in.
///
/// Deliberately not a stub that throws: with no `google-services.json` in the
/// project the app must still build, sign in and take orders, and it does —
/// there is simply nothing to register and no tap to route.
class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Stream<Map<String, Object?>> get onTap =>
      const Stream<Map<String, Object?>>.empty();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> ensureChannel() async {}
}

/// Which store the token belongs to, as the API names it.
String pushPlatformName([TargetPlatform? platform]) =>
    switch (platform ?? defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      _ => 'android',
    };
