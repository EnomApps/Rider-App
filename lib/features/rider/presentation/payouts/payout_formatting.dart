import 'package:flutter/material.dart';

import '../../../../core/widgets/info_tile.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../data/payout_models.dart';

/// How a payout reads on screen, shared by the list and the details screen so
/// the two can never disagree about whether a week has been paid.
extension PayoutPresentation on Payout {
  /// "Paid" only for a completed transfer. Every other status says, in so many
  /// words, that the money has not arrived.
  String statusText(AppLocalizations l10n) {
    switch (status) {
      case PayoutStatus.paid:
        return l10n.payoutStatusPaid;
      case PayoutStatus.pending:
        return l10n.payoutStatusPending;
      case PayoutStatus.processing:
        return l10n.payoutStatusProcessing;
    }
  }

  /// Green is reserved for money that has moved.
  StatusTone get statusTone =>
      isPaid ? StatusTone.positive : StatusTone.warning;

  /// "Sep 7 – Sep 13", in the rider's language where Flutter has one.
  String periodText(BuildContext context, AppLocalizations l10n) {
    final MaterialLocalizations dates = MaterialLocalizations.of(context);
    final DateTime? start = periodStart;
    final DateTime? end = periodEnd;
    return l10n.payoutPeriod(
      start == null ? '—' : dates.formatShortMonthDay(start),
      end == null ? '—' : dates.formatShortMonthDay(end),
    );
  }
}
