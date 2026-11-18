import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../features/rider/data/offer_models.dart';
import '../../features/rider/state/offer_controller.dart';
import '../services/device_setup.dart';
import 'push_service.dart';

/// Rings for a live offer card while the app is on screen, and stops every
/// trace of it when the card goes.
///
/// While the app is away the notification drawn from the push does the
/// ringing — on the alarm stream, repeating — so this only plays sound when
/// the app is in the foreground, where Android draws no notification. Either
/// way, [silence] clears that notification, so answering the card in the app
/// also stops a ring that started in the background.
class AppOfferAlert implements OfferAlert {
  AppOfferAlert({
    required PushService push,
    DeviceSetup device = const DeviceSetup(),
  })  : _push = push,
        _device = device;

  final PushService _push;
  final DeviceSetup _device;

  AudioPlayer? _player;
  Timer? _buzz;

  @override
  Future<void> ring(OrderOffer offer) async {
    // Over the lock screen and screen on, like a call, for as long as the
    // card is up. Switched off again in [silence]. The wake is for a phone
    // that is already locked and dark when the offer reaches a running app.
    unawaited(_device.showOverLockScreen(true));
    unawaited(_device.wakeScreen());

    final bool onScreen = WidgetsBinding.instance.lifecycleState ==
        AppLifecycleState.resumed;
    if (!onScreen) return;

    _buzz?.cancel();
    _buzz = Timer.periodic(
      const Duration(milliseconds: 1200),
      (_) => HapticFeedback.vibrate(),
    );

    try {
      final AudioPlayer player = _player ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      // The alarm stream, so a rider who turned the ringer down still hears
      // a new order.
      await player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.alarm,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
          iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
        ),
      );
      await player.play(AssetSource('sounds/offer_ring.wav'));
    } catch (_) {
      // No sound is better than a crash; the card and vibration still show.
    }
  }

  @override
  Future<void> silence(OrderOffer offer) async {
    _buzz?.cancel();
    _buzz = null;
    try {
      await _player?.stop();
    } catch (_) {}
    await _push.cancelOffer(offer.orderId);
    await _device.showOverLockScreen(false);
  }
}
