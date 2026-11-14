import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/offer_models.dart';
import '../data/order_models.dart';
import '../data/rider_repository.dart';

/// How an accept ended, for the card to word.
sealed class AcceptOutcome {
  const AcceptOutcome();
}

/// 200: the order is this rider's. [order] carries the drop address and the
/// customer's phone, which the offer never did.
class OfferWon extends AcceptOutcome {
  const OfferWon(this.order);

  final RiderOrder order;
}

/// 409: someone was faster, or the order was cancelled.
class OfferTaken extends AcceptOutcome {
  const OfferTaken();
}

/// 410 or 404: the window closed, or it was never this rider's. The card just
/// goes; the countdown already said so.
class OfferGone extends AcceptOutcome {
  const OfferGone();
}

/// 422: the rider cannot take it. [message] is the server's own sentence —
/// "Finish your current delivery first", "Your licence has expired".
class OfferRefused extends AcceptOutcome {
  const OfferRefused(this.message);

  final String? message;
}

/// The network failed. The offer stays up; accepting again is safe because a
/// second accept of the same offer is a 200.
class OfferRetry extends AcceptOutcome {
  const OfferRetry();
}

/// The ringing that goes with a live card: a notification while the app is
/// away, a sound while it is open. Behind an interface so the controller can
/// be tested without a speaker or a notification shade.
abstract class OfferAlert {
  Future<void> ring(OrderOffer offer);
  Future<void> silence(OrderOffer offer);
}

class SilentOfferAlert implements OfferAlert {
  const SilentOfferAlert();

  @override
  Future<void> ring(OrderOffer offer) async {}

  @override
  Future<void> silence(OrderOffer offer) async {}
}

/// The one live order offer, if there is one, and everything that can happen
/// to it: it arrives (by push or by asking the server), it counts down, the
/// rider accepts or declines, or the server withdraws it.
///
/// One card at a time. The server never sends a second offer to a rider with
/// one live, but a duplicate push or a stale resume could, so this guards it.
class OfferController extends ChangeNotifier {
  OfferController({
    required RiderRepository repository,
    OfferAlert alert = const SilentOfferAlert(),
    DateTime Function()? clock,
  })  : _repository = repository,
        _alert = alert,
        _clock = clock ?? DateTime.now;

  final RiderRepository _repository;
  OfferAlert _alert;
  final DateTime Function() _clock;

  OrderOffer? _offer;
  Timer? _ticker;
  bool _isAccepting = false;
  bool _isRejecting = false;

  /// Offer ids already shown, so the same offer arriving twice — push and
  /// resume, or two pushes — puts up one card, once. Kept for the session.
  final Set<String> _seen = <String>{};

  OrderOffer? get offer => _offer;
  bool get isAccepting => _isAccepting;
  bool get isRejecting => _isRejecting;

  Duration get remaining => _offer?.remaining(_clock()) ?? Duration.zero;

  /// Swaps how the card rings, once the app knows whether it is on screen.
  set alert(OfferAlert value) => _alert = value;

  /// Puts [offer] up, unless it is a duplicate, already over, or another card
  /// is live. Returns whether it was shown.
  bool present(OrderOffer offer) {
    if (offer.isExpired(_clock())) return false;
    final OrderOffer? current = _offer;
    if (current != null && current.offerId == offer.offerId) return false;
    if (current != null && !current.isExpired(_clock())) return false;
    if (_seen.contains(offer.offerId) && current == null) return false;

    _seen.add(offer.offerId);
    _offer = offer;
    _startTicker();
    unawaited(_alert.ring(offer));
    notifyListeners();
    return true;
  }

  /// A push. Routes the dispatch types and ignores the rest. Returns true for
  /// `rider.auto_offline`, which the caller turns into flipping duty off.
  bool handleMessage(Map<String, Object?> data) {
    switch (OfferMessage.typeOf(data)) {
      case OfferMessage.offer:
        final OrderOffer? offer = OrderOffer.fromData(data, receivedAt: _clock());
        if (offer != null) present(offer);
        return false;
      case OfferMessage.cancelled:
        withdraw('${data['order_id'] ?? ''}');
        return false;
      case OfferMessage.autoOffline:
        _dismiss();
        return true;
      default:
        return false;
    }
  }

  /// `OFFER_CANCELLED`: dismissed by order id, whichever offer the card came
  /// from, because the server withdraws the order, not one offer of it.
  void withdraw(String orderId) {
    if (_offer?.orderId == orderId) _dismiss();
  }

  /// Asks the server what is live. On cold start and every resume: a data
  /// message can be dropped, duplicated or land on a phone that was off, and
  /// a card for an order someone else collected ten minutes ago is worse
  /// than no card.
  Future<void> sync() async {
    try {
      final OrderOffer? live = await _repository.currentOffer();
      if (live == null) {
        _dismiss();
        return;
      }
      if (_offer != null && _offer!.offerId != live.offerId) _dismiss();
      // A resume should show the card even when the push already did, so
      // the server's answer is not subject to the duplicate guard.
      _seen.remove(live.offerId);
      present(live);
    } catch (_) {
      // Keep what is on screen; the countdown still ends it.
    }
  }

  Future<AcceptOutcome> accept() async {
    final OrderOffer? offer = _offer;
    if (offer == null) return const OfferGone();
    if (_isAccepting) return const OfferRetry();
    _isAccepting = true;
    notifyListeners();

    try {
      final RiderOrder order = await _repository.acceptOffer(offer.offerId);
      _dismiss();
      return OfferWon(order);
    } on ApiException catch (error) {
      switch (error.statusCode) {
        case 409:
          _dismiss();
          return const OfferTaken();
        case 410:
        case 404:
          _dismiss();
          return const OfferGone();
        case 422:
          _dismiss();
          return OfferRefused(error.errorFor('rider') ?? error.message);
      }
      return const OfferRetry();
    } catch (_) {
      return const OfferRetry();
    } finally {
      _isAccepting = false;
      notifyListeners();
    }
  }

  Future<void> reject({String? reason}) async {
    final OrderOffer? offer = _offer;
    if (offer == null || _isRejecting) return;
    _isRejecting = true;
    // Gone from the screen at once: declining should feel instant, and the
    // server's answer changes nothing the rider can act on.
    _dismiss();
    try {
      await _repository.rejectOffer(offer.offerId, reason: reason);
    } catch (_) {
      // The window closes on its own either way.
    } finally {
      _isRejecting = false;
      notifyListeners();
    }
  }

  /// Signed out: no card for the next rider on this phone.
  void reset() {
    _dismiss();
    _seen.clear();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final OrderOffer? offer = _offer;
      if (offer == null) return;
      if (offer.isExpired(_clock())) {
        // Silently: the ring stopping and the circle running out said it.
        _dismiss();
      } else {
        notifyListeners();
      }
    });
  }

  void _dismiss() {
    final OrderOffer? offer = _offer;
    _ticker?.cancel();
    _ticker = null;
    if (offer == null) return;
    _offer = null;
    unawaited(_alert.silence(offer));
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
