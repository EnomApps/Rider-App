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

const String _offersChannelName = 'Incoming orders';
const String _offersChannelDescription =
    'Rings like a call when a new order is offered to you.';
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
  await _ensureOffersChannel(local);
  if (await _handleDispatchMessage(local, message.data)) return;
  await _showDataMessage(local, message);
}

/// The dispatch messages, drawn or cleared here because the app is not on
/// screen to do it. Returns true when [data] was one of them.
Future<bool> _handleDispatchMessage(
  FlutterLocalNotificationsPlugin local,
  Map<String, dynamic> data,
) async {
  switch ('${data['type'] ?? ''}') {
    case 'ORDER_OFFER':
      await _showOffer(local, data);
      return true;
    case 'OFFER_CANCELLED':
      // Stops the ring the moment the order is gone, rather than leaving it
      // to ring out for an order somebody else already has.
      await local.cancel(id: 0, tag: _offerTag('${data['order_id'] ?? ''}'));
      return true;
    case 'rider.auto_offline':
      // Usually comes with its own text; when it does not, say it plainly.
      if (_string(data['title']) == null && _string(data['body']) == null) {
        await local.show(
          id: _uniqueId(),
          title: 'You are offline',
          body: 'You missed 3 orders in a row, so you were set offline. '
              'Go online in the app when you are ready.',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              kOrdersChannelId,
              _ordersChannelName,
              channelDescription: _ordersChannelDescription,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(data),
        );
        return true;
      }
      return false;
  }
  return false;
}

String _offerTag(String orderId) => 'offer-$orderId';

/// The incoming order, drawn like an incoming call: full screen over the lock
/// screen, ringing on the alarm stream until it is answered or gone.
///
/// Written in English: this runs in a background isolate with no access to
/// the rider's chosen language. The card inside the app is translated.
Future<void> _showOffer(
  FlutterLocalNotificationsPlugin local,
  Map<String, dynamic> data,
) async {
  final String orderId = '${data['order_id'] ?? ''}';
  if (orderId.isEmpty) return;

  final DateTime? expiresAt = DateTime.tryParse('${data['expires_at'] ?? ''}');
  final int? secondsLeft = int.tryParse('${data['seconds_left'] ?? ''}');
  int windowMs = (secondsLeft ?? 30) * 1000;
  if (expiresAt != null) {
    final int byClock = expiresAt.difference(DateTime.now()).inMilliseconds;
    // Trust the server's deadline unless this phone's clock is clearly off.
    if (secondsLeft == null || (byClock - windowMs).abs() < 5000) {
      windowMs = byClock;
    }
  }
  // Landed after its window: nothing to ring for.
  if (windowMs <= 0) return;

  final String earnings = _string(data['earnings']) ?? '';
  final String restaurant = _string(data['restaurant']) ?? 'New order';
  final String? distance = _distance(_string(data['pickup_distance_metres']));

  await local.show(
    id: 0,
    title: earnings.isEmpty ? 'New order' : 'New order · Earn ₹$earnings',
    body: distance == null ? restaurant : '$restaurant · $distance away',
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        kOffersChannelId,
        _offersChannelName,
        channelDescription: _offersChannelDescription,
        tag: _offerTag(orderId),
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: false,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        sound: const RawResourceAndroidNotificationSound(_androidSound),
        // FLAG_INSISTENT: the sound repeats until the notification goes.
        additionalFlags: Int32List.fromList(<int>[4]),
        // Gone on its own when the window closes.
        timeoutAfter: windowMs,
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            kOfferDeclineAction,
            'Decline',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            kOfferAcceptAction,
            'Accept',
            showsUserInterface: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        sound: _iosSound,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    ),
    payload: jsonEncode(data),
  );
}

String? _distance(String? metres) {
  final double? m = metres == null ? null : double.tryParse(metres);
  if (m == null) return null;
  return m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
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

  final StreamController<Map<String, Object?>> _data =
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

    // A notification this app drew — an offer, usually — that launched it
    // from cold: its full-screen intent over the lock screen, or a tap on
    // Accept. Read once, after the app has had a moment to subscribe.
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 500), () async {
        final NotificationAppLaunchDetails? launch =
            await _local.getNotificationAppLaunchDetails();
        final NotificationResponse? response = launch?.notificationResponse;
        if (launch?.didNotificationLaunchApp ?? false) {
          if (response != null) _onLocalTap(response);
        }
      }),
    );

    // In the foreground Android draws nothing at all, so an order update that
    // lands while the rider is looking at the app would otherwise be
    // invisible. Dispatch messages go to the app, which shows its own card.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!_data.isClosed) {
        _data.add(Map<String, Object?>.from(message.data));
      }
      if (_isDispatch(message.data)) return;
      unawaited(_showForeground(message));
    });
  }

  static bool _isDispatch(Map<String, dynamic> data) => const <String>{
        'ORDER_OFFER',
        'OFFER_CANCELLED',
        'rider.auto_offline',
      }.contains('${data['type'] ?? ''}');

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
        _taps.add(<String, Object?>{
          ...decoded,
          if (response.actionId != null) kTapAction: response.actionId,
        });
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
  Stream<Map<String, Object?>> get onData => _data.stream;

  @override
  Future<void> cancelOffer(String orderId) =>
      _local.cancel(id: 0, tag: _offerTag(orderId));

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
  Future<NotificationAccess> notificationAccess() async {
    final NotificationSettings settings =
        await _messaging.getNotificationSettings();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional =>
        NotificationAccess.granted,
      AuthorizationStatus.notDetermined => NotificationAccess.askable,
      // iOS never prompts twice. Android reports "denied" before the first
      // prompt as well as after a refusal, and will still prompt.
      AuthorizationStatus.denied => defaultTargetPlatform == TargetPlatform.iOS
          ? NotificationAccess.blocked
          : NotificationAccess.askable,
      AuthorizationStatus.deniedPermanently => NotificationAccess.blocked,
    };
  }

  @override
  Future<bool> notificationsAllowed() async {
    final NotificationSettings settings =
        await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<void> ensureChannel() async {
    await _ensureAndroidChannel(_local);
    await _ensureOffersChannel(_local);
  }
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

/// Creates [kOffersChannelId]: maximum importance, the alarm stream so it
/// rings at low ringer volume, and vibration.
Future<void> _ensureOffersChannel(FlutterLocalNotificationsPlugin local) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;

  await local
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        AndroidNotificationChannel(
          kOffersChannelId,
          _offersChannelName,
          description: _offersChannelDescription,
          importance: Importance.max,
          sound: const RawResourceAndroidNotificationSound(_androidSound),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: true,
          vibrationPattern: Int64List.fromList(<int>[0, 600, 400, 600, 400]),
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

  // Keyed by order with the same tag the server puts on the notification it
  // sends, `order-{id}`. Android identifies a notification by tag and id, and
  // FCM draws tagged ones with id 0, so matching both means an update shown
  // here in the foreground replaces the one the system drew in the
  // background, and the reverse: one live notification per order.
  final String? tag = _orderTag(message);
  await local.show(
    id: tag == null ? _uniqueId() : 0,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        kOrdersChannelId,
        _ordersChannelName,
        channelDescription: _ordersChannelDescription,
        tag: tag,
        importance: Importance.high,
        priority: Priority.high,
        // Android 8 and later take the sound from the channel and ignore
        // this; it is here for the older devices that still read it per
        // notification.
        sound: const RawResourceAndroidNotificationSound(_androidSound),
      ),
      iOS: DarwinNotificationDetails(
        sound: _iosSound,
        // The iOS counterpart of the Android tag: updates to one order
        // group together instead of interleaving with other orders.
        threadIdentifier: tag,
      ),
    ),
    payload: jsonEncode(message.data),
  );
}

/// `order-{id}`, the tag the server sets on every notification about one
/// order. Null when the payload carries no order: two unrelated
/// notifications must not overwrite each other.
String? _orderTag(RemoteMessage message) {
  final String? orderId = _string(message.data['order_id']);
  return orderId == null ? null : 'order-$orderId';
}

/// Something unique for a notification that is not about an order. Kept
/// inside 32 bits: Android ids are ints.
int _uniqueId() => DateTime.now().millisecondsSinceEpoch % 0x7fffffff;

String? _string(Object? raw) {
  if (raw == null) return null;
  final String value = '$raw'.trim();
  return value.isEmpty ? null : value;
}
