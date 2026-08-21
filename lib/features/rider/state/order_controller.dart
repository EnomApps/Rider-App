import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/location_service.dart';
import '../data/order_models.dart';
import '../data/rider_failure.dart';
import '../data/rider_repository.dart';

/// Owns the working half of a shift: the board, the order in hand, and the
/// position ping that keeps the rider in dispatch.
///
/// Kept apart from `RiderController` on purpose. That one answers "may this
/// rider work at all?", which is settled once per session and changes rarely;
/// this one runs timers, polls, and turns over every few seconds. Folding them
/// together would have the gate rebuilding on every location tick.
///
/// Mirrors the same contract as the rest of the app: every action returns
/// `null` on success or a [RiderFailure], so screens neither catch exceptions
/// nor build error strings.
class OrderController extends ChangeNotifier {
  OrderController({
    required RiderRepository repository,
    required LocationService location,
  })  : _repository = repository,
        _location = location;

  final RiderRepository _repository;
  final LocationService _location;

  /// How often the board refreshes while a rider is looking at it. The API
  /// asks for 10-15 seconds; slower than that and a rider watching an empty
  /// board thinks the app is dead, faster and every idle rider in the city is
  /// hammering the same endpoint.
  static const Duration boardInterval = Duration(seconds: 12);

  /// Heartbeat while idle on the board. Coarse on purpose — dispatch only
  /// needs to know which part of town the rider is in.
  static const Duration idlePingInterval = Duration(seconds: 25);

  /// Heartbeat while carrying an order, where a customer is watching the dot
  /// move and the interval is worth the battery.
  static const Duration activePingInterval = Duration(seconds: 10);

  OrderBoard _board = OrderBoard.empty;
  RiderOrder? _active;
  List<RiderOrder> _history = const <RiderOrder>[];

  bool _isLoadingBoard = false;
  bool _isLoadingActive = false;
  bool _isLoadingHistory = false;

  /// True while an accept, pickup, release or deliver is in flight. One flag
  /// rather than one per action: a rider can only be doing one of these at a
  /// time, and every button on the working screen should be inert while any of
  /// them is running.
  bool _isActing = false;

  RiderFailure? _boardFailure;
  RiderFailure? _historyFailure;

  /// Why the last fix failed, if it did. Distinct from a [RiderFailure]
  /// because the remedy is on the device rather than the network — a settings
  /// screen, not a retry button.
  LocationDenial? _locationDenial;

  /// The server's answer to the last ping. False means it has stopped
  /// tracking — the rider clocked off — and the heartbeat stops rather than
  /// pinging into a void.
  bool _isTracking = false;

  Timer? _boardTimer;
  Timer? _pingTimer;

  /// The cadence [_pingTimer] is currently running at, so [startTracking] can
  /// tell "already running" from "running, but at the wrong interval".
  Duration? _interval;

  /// True while a ping is in flight, so a slow fix on a bad connection cannot
  /// stack pings up behind each other.
  bool _pinging = false;

  OrderBoard get board => _board;

  List<RiderOrder> get available => _board.orders;

  BoardAvailability get availability => _board.availability;

  RiderOrder? get active => _active;

  List<RiderOrder> get history => _history;

  bool get isLoadingBoard => _isLoadingBoard;

  bool get isLoadingActive => _isLoadingActive;

  bool get isLoadingHistory => _isLoadingHistory;

  bool get isActing => _isActing;

  RiderFailure? get boardFailure => _boardFailure;

  RiderFailure? get historyFailure => _historyFailure;

  LocationDenial? get locationDenial => _locationDenial;

  bool get isTracking => _isTracking;

  /// True when the rider is carrying something. The home screen leads with the
  /// working card instead of the board when this is true.
  bool get hasActiveOrder => _active != null;

  // --- The order in hand ---------------------------------------------------

  /// Resumes whatever the rider was already carrying.
  ///
  /// Called when the home screen appears, not when the order is accepted: a
  /// shift outlives an app process, and an order taken before a crash is still
  /// the rider's. Never resumed from local state for the same reason.
  Future<RiderFailure?> loadActive({bool silent = false}) async {
    if (!silent) {
      _isLoadingActive = true;
      notifyListeners();
    }

    try {
      _active = await _repository.activeOrder();
      return null;
    } on ApiException catch (error) {
      return riderFailureFrom(error);
    } catch (_) {
      return RiderFailure.unknown;
    } finally {
      _isLoadingActive = false;
      notifyListeners();
    }
  }

  // --- The board -----------------------------------------------------------

  /// Starts polling and fetches immediately.
  ///
  /// Idempotent, so a screen can call it from `didChangeDependencies` without
  /// tracking whether it already has.
  void startBoardPolling() {
    if (_boardTimer != null) return;
    _boardTimer = Timer.periodic(boardInterval, (_) => refreshBoard(silent: true));
    unawaited(refreshBoard());
  }

  /// Stops polling. Called when the board leaves the screen — a rider looking
  /// at their profile should not be polling a list they cannot see.
  void stopBoardPolling() {
    _boardTimer?.cancel();
    _boardTimer = null;
  }

  Future<RiderFailure?> refreshBoard({bool silent = false}) async {
    // A rider carrying an order cannot take another, and the API says so with
    // an empty board. Skipping the call keeps the working screen off a request
    // whose answer is already known.
    if (_active != null) return null;

    if (!silent) {
      _isLoadingBoard = true;
      notifyListeners();
    }

    try {
      _board = await _repository.availableOrders();
      _boardFailure = null;
      return null;
    } on ApiException catch (error) {
      _boardFailure = riderFailureFrom(error);
      return _boardFailure;
    } catch (_) {
      _boardFailure = RiderFailure.unknown;
      return _boardFailure;
    } finally {
      _isLoadingBoard = false;
      notifyListeners();
    }
  }

  // --- History -------------------------------------------------------------

  Future<RiderFailure?> loadHistory() async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      final List<RiderOrder> orders = await _repository.orderHistory();
      // The active order comes back from the same endpoint. It has its own
      // screen, and listing it under "past deliveries" would read as though it
      // were finished.
      _history = orders
          .where((RiderOrder order) => !order.status.isActive)
          .toList(growable: false);
      _historyFailure = null;
      return null;
    } on ApiException catch (error) {
      _historyFailure = riderFailureFrom(error);
      return _historyFailure;
    } catch (_) {
      _historyFailure = RiderFailure.unknown;
      return _historyFailure;
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// One order in full, for the details screen.
  ///
  /// Returns the order or throws nothing — the screen gets a null and the
  /// failure separately, like every other call here.
  Future<RiderOrder?> orderDetails(String orderId) async {
    try {
      return await _repository.order(orderId);
    } catch (_) {
      return null;
    }
  }

  // --- The four actions ----------------------------------------------------

  /// Takes the order. First to accept wins.
  ///
  /// A 422 means another rider got there first, which is the ordinary outcome
  /// on a shared board rather than a fault — so the board refreshes itself on
  /// the way out and the screen reports it as information.
  Future<RiderFailure?> accept(String orderId) {
    return _act(
      validationFailure: RiderFailure.orderTaken,
      () async {
        _active = await _repository.acceptOrder(orderId);
      },
      onFailure: (RiderFailure failure) async {
        if (failure == RiderFailure.orderTaken ||
            failure == RiderFailure.orderGone) {
          await refreshBoard(silent: true);
        }
      },
    );
  }

  /// Confirms collection with the merchant's code.
  ///
  /// A wrong code is a 422 on `pickup_code` and the rider simply retypes it;
  /// there is no path to "I collected it" without the code, because that code
  /// is the evidence a disputed delivery is settled with.
  Future<RiderFailure?> confirmPickup(String orderId, String code) {
    return _act(
      validationFailure: RiderFailure.wrongPickupCode,
      () async {
        _active = await _repository.confirmPickup(orderId, code);
      },
    );
  }

  /// Puts the order back on the board. Only ever offered before collection.
  Future<RiderFailure?> release(String orderId, {String? reason}) {
    return _act(() async {
      await _repository.releaseOrder(orderId, reason: reason);
      // Released, so nothing is in hand — and the board it went back onto is
      // worth refetching, since the rider is looking at it again.
      _active = null;
      await refreshBoard(silent: true);
    });
  }

  /// Closes the order out. The server sets the rider back to `available` and
  /// increments `completed_deliveries`, which is why the caller refreshes the
  /// profile afterwards rather than adding one locally.
  Future<RiderFailure?> deliver(String orderId) {
    return _act(() async {
      await _repository.confirmDelivery(orderId);
      _active = null;
    });
  }

  // --- Location heartbeat --------------------------------------------------

  /// Starts pinging, at the interval that suits what the rider is doing.
  ///
  /// Safe to call repeatedly — the interval is recomputed each time, which is
  /// how carrying an order tightens it without a separate call.
  void startTracking() {
    final Duration interval =
        _active == null ? idlePingInterval : activePingInterval;

    // Already running at the right cadence. Restarting would reset the period
    // and, worse, fire an immediate extra ping every time a screen rebuilt.
    if (_pingTimer != null && _interval == interval) return;

    _pingTimer?.cancel();
    _interval = interval;
    _pingTimer = Timer.periodic(interval, (_) => unawaited(_ping()));
    unawaited(_ping());
  }

  void stopTracking() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _interval = null;
    if (_isTracking) {
      _isTracking = false;
      notifyListeners();
    }
  }


  /// One position, sent.
  ///
  /// Nothing here surfaces an error to the rider mid-shift: a ping that misses
  /// is caught by the next one, and a notification every time a phone loses
  /// GPS under a flyover would be unusable. The one thing worth recording is a
  /// refused permission, which no amount of retrying will fix.
  Future<void> _ping() async {
    if (_pinging) return;
    _pinging = true;

    try {
      final RiderPosition position = await _location.current(
        highAccuracy: _active != null,
      );
      _locationDenial = null;

      final bool tracking = await _repository.sendLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMetres: position.accuracyMetres,
      );

      // `tracking: false` is the server saying this rider is off duty. Not an
      // error — just stop the timer.
      if (!tracking) {
        stopTracking();
        return;
      }

      if (!_isTracking) {
        _isTracking = true;
        notifyListeners();
      }
    } on LocationException catch (error) {
      // The device will not give a position and no retry changes that, so the
      // timer stops and the board explains itself instead of sitting empty.
      _locationDenial = error.denial;
      stopTracking();
    } catch (_) {
      // A ping that failed on the network. The next tick tries again.
    } finally {
      _pinging = false;
    }
  }

  /// Asks for location permission up front, when the rider goes online.
  ///
  /// Doing it here rather than on the first ping means the system dialog
  /// appears while the rider is looking at the button they just pressed,
  /// instead of half a minute later over whatever screen they moved on to.
  Future<RiderFailure?> primeLocation() async {
    try {
      await _location.ensurePermission();
      _locationDenial = null;
      notifyListeners();
      return null;
    } on LocationException catch (error) {
      _locationDenial = error.denial;
      notifyListeners();
      return RiderFailure.locationUnavailable;
    }
  }

  // --- Plumbing ------------------------------------------------------------

  Future<RiderFailure?> _act(
    Future<void> Function() action, {
    RiderFailure validationFailure = RiderFailure.invalidDetails,
    Future<void> Function(RiderFailure failure)? onFailure,
  }) async {
    if (_isActing) return null;
    _isActing = true;
    notifyListeners();

    RiderFailure? failure;
    try {
      await action();
    } on ApiException catch (error) {
      failure = orderFailureFrom(error, validationFailure: validationFailure);
    } catch (_) {
      failure = RiderFailure.unknown;
    } finally {
      _isActing = false;
      notifyListeners();
    }

    if (failure != null && onFailure != null) await onFailure(failure);

    // Whatever just happened changed what the rider is carrying, and that
    // decides the ping cadence: a fresh order tightens it, a delivered one
    // relaxes it.
    if (failure == null && _pingTimer != null) startTracking();

    return failure;
  }

  /// Drops everything on sign-out, timers included. A heartbeat that outlived
  /// its session would keep a signed-out rider on the map.
  void reset() {
    stopBoardPolling();
    stopTracking();
    _board = OrderBoard.empty;
    _active = null;
    _history = const <RiderOrder>[];
    _boardFailure = null;
    _historyFailure = null;
    _locationDenial = null;
    _isLoadingBoard = false;
    _isLoadingActive = false;
    _isLoadingHistory = false;
    _isActing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopBoardPolling();
    stopTracking();
    super.dispose();
  }
}
