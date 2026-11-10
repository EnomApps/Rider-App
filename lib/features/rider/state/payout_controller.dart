import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/payout_models.dart';
import '../data/payout_repository.dart';
import '../data/rider_failure.dart';

/// The weekly pay statements.
///
/// Fetched when the screen opens rather than polled: a week's figures change
/// once, when the payout run settles it, and a rider checking their pay pulls
/// to refresh.
///
/// Same contract as the other controllers: actions return `null` on success or
/// a [RiderFailure], so the screens neither catch exceptions nor build error
/// strings.
class PayoutController extends ChangeNotifier {
  PayoutController({required PayoutRepository repository})
    : _repository = repository;

  final PayoutRepository _repository;

  List<Payout> _payouts = const <Payout>[];
  bool _isLoading = false;
  bool _hasLoaded = false;
  RiderFailure? _failure;

  List<Payout> get payouts => _payouts;
  bool get isLoading => _isLoading;

  /// False until the first answer arrives, so the screen can tell "no weeks
  /// yet" from "not asked yet".
  bool get hasLoaded => _hasLoaded;

  RiderFailure? get failure => _failure;

  Future<RiderFailure?> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      _payouts = await _repository.payouts();
      _hasLoaded = true;
      _failure = null;
      return null;
    } on ApiException catch (error) {
      _failure = riderFailureFrom(error);
      return _failure;
    } catch (_) {
      _failure = RiderFailure.unknown;
      return _failure;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// One week, for the details screen. Null on any failure — the screen keeps
  /// the list row it was opened with, which does not stop being true because
  /// one request missed.
  Future<Payout?> details(String id) async {
    try {
      return await _repository.payout(id);
    } catch (_) {
      return null;
    }
  }

  /// Dropped on sign-out, so the next rider on this phone never sees the last
  /// one's pay.
  void reset() {
    _payouts = const <Payout>[];
    _hasLoaded = false;
    _failure = null;
    notifyListeners();
  }
}
