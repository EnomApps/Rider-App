import 'package:flutter/foundation.dart';

import '../router/app_router.dart';

/// Where a notification tap should land, and what it should refresh.
///
/// Pure, so the routing rule is provable without a device or a push at all —
/// which matters, because the only other way to test it is to have the server
/// send a real notification to a real phone.
///
/// The rider app has one destination and not several: what a signed-in rider
/// is entitled to see is the API's decision, resolved inside `RiderGateScreen`
/// ([AppRoutes.home]). A push that tried to name a screen directly would be
/// guessing at a state the server owns — an offer that has already gone to
/// somebody else, a rider who has been taken off duty.
@immutable
class PushDestination {
  const PushDestination({required this.routeName, this.refreshBoard = false});

  final String routeName;

  /// Whether the board should be re-fetched on arrival.
  ///
  /// An offer notification is only worth tapping if the order behind it is on
  /// screen when the rider gets there, and the board polls on its own schedule
  /// — up to [OrderController.boardInterval] behind.
  final bool refreshBoard;

  /// Reads the `data` payload the server sends alongside the notification.
  ///
  /// Returns null for anything this build cannot place. Landing nowhere is the
  /// right answer for an unrecognised push: new notification types will ship
  /// server-side long before the app that understands them.
  static PushDestination? fromData(Map<String, Object?> data) {
    final String type = '${data['type'] ?? ''}'.trim().toLowerCase();
    if (type.isEmpty) return null;

    // Not about work: a promotion has no place interrupting a shift, and
    // nothing in this app would know what to do with one.
    const Set<String> notAboutAnOrder = <String>{'promo', 'promotion', 'news'};
    if (notAboutAnOrder.contains(type)) return null;

    if (!type.startsWith('order.')) return null;

    // `order.offer` is the one notification that is not a courtesy: an order
    // sits going cold until a rider takes it, so the board is refreshed rather
    // than left showing whatever it held when the phone buzzed.
    return PushDestination(
      routeName: AppRoutes.home,
      refreshBoard: type == 'order.offer',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PushDestination &&
      other.routeName == routeName &&
      other.refreshBoard == refreshBoard;

  @override
  int get hashCode => Object.hash(routeName, refreshBoard);
}
