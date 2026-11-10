import 'kyc_models.dart' show nullableString;

/// Where a week's money is.
///
/// Only [paid] means the money has left. Everything else — including a status
/// this build has never seen — reads as not yet sent, because telling a rider
/// their money is in the bank when it is not is the worst mistake this screen
/// can make, and a new server status is far more likely to be an intermediate
/// step than a new way of being paid.
enum PayoutStatus {
  /// Worked out, not transferred. Every payout is this until bank transfers
  /// are wired server-side.
  pending,

  /// The transfer has gone through. `paid_at` and `reference` come with it.
  paid,

  /// Anything else the server sends. Rendered as "being processed".
  processing;

  static PayoutStatus fromWire(Object? raw) {
    switch (nullableString(raw)?.toLowerCase()) {
      case 'paid':
        return PayoutStatus.paid;
      case 'pending':
        return PayoutStatus.pending;
      default:
        return PayoutStatus.processing;
    }
  }
}

/// One line under "Deductions".
///
/// [label] and [note] are the server's own words, already in the rider's
/// language. They are rendered verbatim and never rebuilt client-side: the
/// wording is translated server-side, and a change of TDS rate has to reach
/// riders without an app release.
class PayoutDeduction {
  const PayoutDeduction({required this.label, required this.amount, this.note});

  final String label;
  final double amount;
  final String? note;

  factory PayoutDeduction.fromJson(Map<String, dynamic> json) {
    return PayoutDeduction(
      label: nullableString(json['label']) ?? '',
      amount: _num(json['amount']),
      note: nullableString(json['note']),
    );
  }
}

/// One week's pay, from `GET /v1/rider/payouts`.
class Payout {
  const Payout({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.deliveryEarnings,
    required this.referralEarnings,
    required this.carriedIn,
    required this.gross,
    required this.deductionsTotal,
    required this.deductions,
    required this.net,
    required this.status,
    this.paidAt,
    this.reference,
  });

  /// Null when the row carries no id, in which case the details screen shows
  /// the list row as it is rather than refetching it.
  final String? id;

  final DateTime? periodStart;
  final DateTime? periodEnd;

  final double deliveryEarnings;
  final double referralEarnings;

  /// Money from an earlier week that was too small to transfer on its own and
  /// was folded into this one.
  final double carriedIn;

  final double gross;
  final double deductionsTotal;

  /// Empty while TDS is switched off. An empty list hides the Deductions row
  /// entirely — "Deductions: ₹0" makes a rider wonder what was taken.
  final List<PayoutDeduction> deductions;

  final double net;
  final PayoutStatus status;
  final DateTime? paidAt;

  /// The bank's transfer reference. Only present once [isPaid].
  final String? reference;

  /// The one question the whole screen hangs on. Decided by the status alone:
  /// a `paid_at` or a `reference` without a `paid` status is not a transfer.
  bool get isPaid => status == PayoutStatus.paid;

  bool get hasDeductions => deductions.isNotEmpty;

  bool get hasCarriedIn => carriedIn > 0;

  bool get hasReferralEarnings => referralEarnings > 0;

  factory Payout.fromJson(Map<String, dynamic> json) {
    final Object? rawDeductions = json['deductions'];
    return Payout(
      id: nullableString(json['id']),
      periodStart: _date(json['period_start']),
      periodEnd: _date(json['period_end']),
      deliveryEarnings: _num(json['delivery_earnings']),
      referralEarnings: _num(json['referral_earnings']),
      carriedIn: _num(json['carried_in']),
      gross: _num(json['gross']),
      deductionsTotal: _num(json['deductions_total']),
      deductions: <PayoutDeduction>[
        if (rawDeductions is List<Object?>)
          for (final Object? raw in rawDeductions)
            if (raw is Map<String, dynamic>) PayoutDeduction.fromJson(raw),
      ],
      net: _num(json['net']),
      status: PayoutStatus.fromWire(json['status']),
      paidAt: _dateTime(json['paid_at']),
      reference: nullableString(json['reference']),
    );
  }
}

double _num(Object? raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse('$raw') ?? 0;
}

/// A calendar date such as `2026-09-07`, kept as a local date so it does not
/// slide a day either way when formatted.
DateTime? _date(Object? raw) {
  final String? text = nullableString(raw);
  if (text == null) return null;
  final DateTime? parsed = DateTime.tryParse(text);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _dateTime(Object? raw) {
  final String? text = nullableString(raw);
  return text == null ? null : DateTime.tryParse(text)?.toLocal();
}
