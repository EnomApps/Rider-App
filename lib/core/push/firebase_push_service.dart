import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_service.dart';

/// Shown in the system settings under the channel name. The id is what the
/// server posts to; this is only ever read by a rider.
const String _ordersChannelName = 'Order alerts';
const String _ordersChannelDescription =
    'New delivery offers and updates to the order you are carrying.';

/// The spoken "Nexmile" that plays instead of the device's default tone.
///
/// Android resolves this against `res/raw` and wants the bare resource name;
/// iOS resolves it against the app bundle and wants the extension. Two names
/// for one sound, which is why both are spelled out here rather than derived.
///
/// The sound is baked into the channel at the moment Android first creates it
/// and cannot be changed afterwards — an existing install keeps whatever it
/// was created with. Changing it in a shipped app means a new channel id, and
/// the server posts to `nexmile_orders` by name, so that is a coordinated
/// change rather than a one-line edit here.
const String _androidSound = 'nexmile';
const String _iosSound = 'nexmile.caf';

/// Handles a message that arrived while the app was not in the foreground.
///
/// Runs in its own isolate with no access to anything this one holds, so it
/// does the one thing that cannot wait: draws the notification for a
/// **data-only** message, which Android otherwise discards without a trace. A
/// message that carries its own `notification` block is already on screen,
/// drawn by the system — redrawing it here is how an order update arrives
/// twice.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.notification != null) return;

  await Firebase.initializeApp();
  final FlutterLocalNotificationsPlugin local = FlutterLocalNotificationsPlugin();
  await local.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  await _ensureAndroidChannel(local);
  await _showDataMessage(local, message);
}

/// Firebase Cloud Messaging, behind [PushService].
///
/// Nothing above this class knows Firebase exists: registration, token
/// rotation and tap routing are all ordinary Dart tested against the
/// interface. This is the only file that needs a `google-services.json` and a
/// real phone to prove.
class FirebasePushService implements PushService {
  FirebasePushService._(this._messaging, this._local);

  /// Starts the transport, or returns null when this build cannot carry push.
  ///
  /// A missing `google-services.json`, a device with no Play Services, or a
  /// Firebase project the bundle id is not registered in all land here. None
  /// of them is a reason to fail a launch: the caller falls back to
  /// [NoopPushService] and the app takes orders exactly as it did before.
  static Future<FirebasePushService?> start() async {
    try {
      await Firebase.initializeApp();

      final FlutterLocalNotificationsPlugin local =
          FlutterLocalNotificationsPlugin();
      final FirebasePushService service =
          FirebasePushService._(FirebaseMessaging.instance, local);

      await local.initialize(
        settings: const InitializationSettings(
          // The launcher icon rather than a dedicated notification asset:
          // Android tints and masks it, and a silhouette can be added later
          // without touching this seam.
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Permission is asked for in [requestPermission] instead, at the
          // point where there is an order worth being notified about.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: service._onLocalTap,
      );

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      service._listen();

      // The only way to send this build a test notification from the Firebase
      // console is to paste its token in, and the token is otherwise never
      // seen — it goes straight to the server. Debug builds only.
      if (kDebugMode) {
        unawaited(
          service
              .token()
              .then((String? value) => debugPrint('FCM token: $value')),
        );
      }

      return service;
    } catch (error, stack) {
      // Never fatal. A build with no Firebase config is the normal state of
      // this repo until the console credentials land.
      debugPrint('Push unavailable: $error');
      assert(() {
        debugPrintStack(stackTrace: stack);
        return true;
      }());
      return null;
    }
  }

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;

  final StreamController<Map<String, Object?>> _taps =
      StreamController<Map<String, Object?>>.broadcast();

  void _listen() {
    // A tap on a notification the system drew while the app was backgrounded.
    FirebaseMessaging.onMessageOpenedApp.listen(_emitTap);

    // The app was not running at all: this resolves once, with the message
    // that launched it, and null every other time.
    unawaited(
      _messaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) _emitTap(message);
      }),
    );

    // In the foreground Android draws nothing at all, so an order update that
    // lands while the rider is looking at the app would otherwise be
    // invisible.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      unawaited(_showForeground(message));
    });
  }

  Future<void> _showForeground(RemoteMessage message) async {
    // iOS is told below to present banners itself, so drawing a second one
    // here would double every foreground notification on that platform.
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        message.notification != null) {
      return;
    }
    await _showDataMessage(_local, message);
  }

  void _emitTap(RemoteMessage message) {
    if (_taps.isClosed) return;
    _taps.add(Map<String, Object?>.from(message.data));
  }

  /// A tap on a notification this app drew itself, rather than the system.
  /// The payload is the FCM data map, carried across as JSON.
  void _onLocalTap(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null || payload.isEmpty || _taps.isClosed) return;
    try {
      final Object? decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _taps.add(Map<String, Object?>.from(decoded));
      }
    } catch (_) {
      // A payload this build cannot read routes nowhere, which is the same
      // answer as an unrecognised push.
    }
  }

  @override
  Future<String?> token() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<Map<String, Object?>> get onTap => _taps.stream;

  @override
  Future<bool> requestPermission() async {
    final NotificationSettings settings = await _messaging.requestPermission();

    // iOS shows nothing in the foreground unless it is asked to. Android
    // ignores this call.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<void> ensureChannel() => _ensureAndroidChannel(_local);
}

/// Creates [kOrdersChannelId] if it is not already there.
///
/// Android ignores a second call for an existing id, so this is safe on every
/// launch — and it has to run on every launch, because the channel is gone
/// after an app reinstall.
Future<void> _ensureAndroidChannel(FlutterLocalNotificationsPlugin local) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;

  await local
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          kOrdersChannelId,
          _ordersChannelName,
          description: _ordersChannelDescription,
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound(_androidSound),
        ),
      );
}

/// Draws a notification for a message the system did not draw itself.
///
/// The title and body come from the `notification` block when there is one and
/// from `data` when there is not, because a data-only message is all the
/// server sends when it wants the app to decide how to present it.
Future<void> _showDataMessage(
  FlutterLocalNotificationsPlugin local,
  RemoteMessage message,
) async {
  final String? title =
      message.notification?.title ?? _string(message.data['title']);
  final String? body =
      message.notification?.body ?? _string(message.data['body']);

  // Nothing to show is not an error: a silent data message may exist only to
  // nudge the app into refreshing.
  if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
    return;
  }

  await local.show(
    // Keyed by order, so a later update to the same order replaces the earlier
    // one instead of stacking four rows for one delivery.
    id: _notificationId(message),
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        kOrdersChannelId,
        _ordersChannelName,
        channelDescription: _ordersChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        // Android 8 and later take the sound from the channel and ignore
        // this; it is here for the older devices that still read it per
        // notification.
        sound: RawResourceAndroidNotificationSound(_androidSound),
      ),
      iOS: DarwinNotificationDetails(sound: _iosSound),
    ),
    payload: jsonEncode(message.data),
  );
}

/// A stable id per order, falling back to something unique when the payload
/// carries no order — two unrelated notifications must not overwrite each
/// other. Kept inside 32 bits: Android ids are ints.
int _notificationId(RemoteMessage message) {
  final String? orderId = _string(message.data['order_id']);
  final int? parsed = orderId == null ? null : int.tryParse(orderId.trim());
  if (parsed != null) return parsed % 0x7fffffff;
  return DateTime.now().millisecondsSinceEpoch % 0x7fffffff;
}

String? _string(Object? raw) {
  if (raw == null) return null;
  final String value = '$raw'.trim();
  return value.isEmpty ? null : value;
}
