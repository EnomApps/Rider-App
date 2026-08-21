import 'package:flutter/material.dart';

import '../../../../core/widgets/info_tile.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../data/order_models.dart';

/// How an order reads on screen.
///
/// Gathered in one place because the board, the working screen, the details
/// screen and the history list all render the same handful of values, and three
/// of them getting the cash amount right while the fourth quietly rounds it
/// differently is exactly the bug that costs a rider money.
extension OrderPresentation on RiderOrder {
  /// The status in the rider's own language.
  ///
  /// Falls back to the API's English `status_label` only for a status this
  /// build has never seen — better a word the rider can look up than a blank
  /// where the state should be.
  String statusText(AppLocalizations l10n) {
    switch (status) {
      case OrderStatus.preparing:
        return l10n.orderPreparing;
      case OrderStatus.readyForPickup:
        return l10n.orderReadyForPickup;
      case OrderStatus.assigned:
        return l10n.orderAssigned;
      case OrderStatus.pickedUp:
        return l10n.orderPickedUp;
      case OrderStatus.outForDelivery:
        return l10n.orderOutForDelivery;
      case OrderStatus.delivered:
        return l10n.orderDelivered;
      case OrderStatus.cancelled:
        return l10n.orderCancelled;
      case OrderStatus.unknown:
        return statusLabel;
    }
  }

  StatusTone get statusTone {
    switch (status) {
      case OrderStatus.delivered:
        return StatusTone.positive;
      case OrderStatus.cancelled:
        return StatusTone.negative;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.outForDelivery:
        return StatusTone.warning;
      case OrderStatus.preparing:
      case OrderStatus.readyForPickup:
      case OrderStatus.unknown:
        return StatusTone.neutral;
    }
  }
}

/// Money, as the rider reads it off a note.
///
/// Two decimals only when there are paise to show: a fare of ₹40 written as
/// "₹40.00" invites a second look at a counter, and the whole point of this
/// number is that it can be read at a glance.
String formatAmount(AppLocalizations l10n, double amount) {
  final bool whole = amount == amount.roundToDouble();
  return l10n.amountRupees(
    whole ? amount.round().toString() : amount.toStringAsFixed(2),
  );
}

/// Distance, in the unit that suits it.
///
/// Metres below a kilometre — "800 m" means something to someone deciding
/// whether to take a job; "0.8 km" does not. Returns null when the API sent no
/// distance, which happens on the board before a position has been reported.
String? formatDistance(AppLocalizations l10n, int? metres) {
  if (metres == null) return null;
  if (metres < 1000) return l10n.distanceMetres('$metres');
  return l10n.distanceKilometres((metres / 1000).toStringAsFixed(1));
}

/// A clock time for a timeline row. Date-free: every stamp on a delivery is
/// from the last hour or two, and a date beside it is noise.
String formatTime(BuildContext context, DateTime value) {
  return TimeOfDay.fromDateTime(value.toLocal()).format(context);
}
