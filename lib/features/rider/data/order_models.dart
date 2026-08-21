import 'package:flutter/foundation.dart';

import 'kyc_models.dart' show nullableString;

/// Where an order is in its life, from the rider's point of view.
///
/// The API sends a free-form string and a `status_label` beside it. The label
/// is English-only, so it is decoded into this enum and translated locally;
/// [unknown] keeps a status this build predates from throwing, and the screens
/// fall back to the server's label when they meet one.
enum OrderStatus {
  /// Cooking. On the board, not yet anyone's.
  preparing,

  /// Out of the kitchen and waiting for a rider.
  readyForPickup,

  /// This rider has taken it. Ride to the restaurant.
  assigned,

  /// Collected. The food is in the bag.
  pickedUp,

  /// On the way to the customer.
  outForDelivery,

  /// Done.
  delivered,

  cancelled,

  unknown;

  static OrderStatus fromWire(Object? raw) {
    switch (raw) {
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready_for_pickup':
      case 'ready':
        return OrderStatus.readyForPickup;
      case 'assigned':
      case 'rider_assigned':
        return OrderStatus.assigned;
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.unknown;
    }
  }

  /// True while the order is still the rider's problem.
  ///
  /// Drives whether the working screen stays up: a delivered or cancelled
  /// order is history, everything else is a job in progress.
  bool get isActive {
    switch (this) {
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.outForDelivery:
        return true;
      case OrderStatus.preparing:
      case OrderStatus.readyForPickup:
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
      case OrderStatus.unknown:
        return false;
    }
  }

  /// True once the food is in the rider's hands.
  ///
  /// The API refuses a release after this point — food that has left the
  /// kitchen has to be delivered — so the hand-back button is hidden rather
  /// than offered and then rejected.
  bool get isCollected {
    return this == OrderStatus.pickedUp || this == OrderStatus.outForDelivery;
  }
}

/// Why the board is empty, straight from `meta.can_accept`.
///
/// An empty board is the normal case, not an error, and the reasons need
/// different screens: "go online" is a button, "you are already carrying one"
/// is a redirect, and "waiting for orders" is just waiting. Collapsing them
/// into one "nothing here" state would leave an offline rider staring at a
/// blank list wondering why nothing arrives.
enum BoardAvailability {
  /// On duty, dispatchable, board simply has nothing on it right now.
  available,

  /// Duty status is `offline` or `on_break`.
  offline,

  /// KYC not approved, or documents lapsed.
  notVerified,

  /// Already carrying an order — finish it first.
  onOrder,

  /// No position sent yet, so dispatch cannot rank anything by distance.
  noLocation,

  unknown;

  static BoardAvailability fromWire(Object? raw) {
    // The live API sends a JSON boolean here even though the schema documents
    // `can_accept` as a string. A bare `true` is eligibility with no reason
    // attached; a bare `false` is ineligibility with no reason attached, which
    // is [unknown] rather than any specific case — the board then works the
    // reason out from what the device already knows. Falling through to the
    // string cases would decode every boolean as `unknown`, and the four
    // explanatory empty states would never appear.
    if (raw is bool) {
      return raw ? BoardAvailability.available : BoardAvailability.unknown;
    }

    switch (raw) {
      case 'yes':
      case 'available':
      case 'true':
        return BoardAvailability.available;
      case 'offline':
      case 'on_break':
        return BoardAvailability.offline;
      case 'not_verified':
      case 'unverified':
      case 'documents_expired':
        return BoardAvailability.notVerified;
      case 'on_order':
      case 'busy':
        return BoardAvailability.onOrder;
      case 'no_location':
      case 'location_missing':
        return BoardAvailability.noLocation;
      default:
        return BoardAvailability.unknown;
    }
  }
}

/// One choice attached to a line — "Large", "Extra cheese".
@immutable
class OrderItemOption {
  const OrderItemOption({
    required this.groupName,
    required this.name,
    required this.priceDelta,
  });

  final String groupName;
  final String name;
  final double priceDelta;

  static OrderItemOption fromJson(Map<String, dynamic> json) {
    return OrderItemOption(
      groupName: nullableString(json['group_name']) ?? '',
      name: nullableString(json['name']) ?? '',
      priceDelta: _num(json['price_delta']),
    );
  }
}

/// A line on the ticket.
///
/// The rider does not price anything — the totals are settled before the order
/// reaches the board — so this exists to answer "is the bag complete?" at the
/// counter, which is why the quantity and the options are what the UI leads
/// with rather than the money.
@immutable
class OrderItem {
  const OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.lineTotal,
    required this.isVeg,
    this.notes,
    this.options = const <OrderItemOption>[],
  });

  final int id;
  final String name;
  final int quantity;
  final double lineTotal;
  final bool isVeg;
  final String? notes;
  final List<OrderItemOption> options;

  static OrderItem fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: _int(json['id']),
      name: nullableString(json['name']) ?? '',
      quantity: _int(json['quantity']),
      lineTotal: _num(json['line_total']),
      isVeg: json['is_veg'] as bool? ?? false,
      notes: nullableString(json['notes']),
      options: <OrderItemOption>[
        for (final Object? raw
            in json['options'] as List<Object?>? ?? const <Object?>[])
          if (raw is Map<String, dynamic>) OrderItemOption.fromJson(raw),
      ],
    );
  }
}

/// Where the food is collected.
@immutable
class OrderPickup {
  const OrderPickup({
    required this.address,
    this.name,
    this.phone,
    this.latitude,
    this.longitude,
    this.distanceMetres,
  });

  final String address;
  final String? name;
  final String? phone;
  final double? latitude;
  final double? longitude;

  /// How far the restaurant is from the rider's last reported position. Absent
  /// when no position has been sent, which is also why the board can come back
  /// empty.
  final int? distanceMetres;

  bool get hasCoordinates => latitude != null && longitude != null;

  static OrderPickup fromJson(Map<String, dynamic> json) {
    return OrderPickup(
      address: nullableString(json['address']) ?? '',
      name: nullableString(json['name']),
      phone: nullableString(json['phone']),
      latitude: _nullableNum(json['latitude']),
      longitude: _nullableNum(json['longitude']),
      distanceMetres: _nullableInt(json['distance_metres']),
    );
  }
}

/// Where the food is going.
///
/// Absent on the board and present once accepted — that is a server decision,
/// not an oversight: a list every on-duty rider can poll must not double as a
/// directory of where customers live.
@immutable
class OrderDropoff {
  const OrderDropoff({
    required this.contactName,
    required this.contactPhone,
    required this.address,
    this.latitude,
    this.longitude,
  });

  final String contactName;
  final String contactPhone;
  final String address;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  static OrderDropoff fromJson(Map<String, dynamic> json) {
    return OrderDropoff(
      contactName: nullableString(json['contact_name']) ?? '',
      contactPhone: nullableString(json['contact_phone']) ?? '',
      address: nullableString(json['address']) ?? '',
      latitude: _nullableNum(json['latitude']),
      longitude: _nullableNum(json['longitude']),
    );
  }
}

/// `RiderOrderResource` — the board entry and the working screen both.
///
/// One model for both because they are the same resource at two moments in its
/// life: the board omits [dropoff] and the item list, the accepted order fills
/// them in. Splitting it would mean re-deriving the same order twice from two
/// shapes that agree on everything else.
@immutable
class RiderOrder {
  const RiderOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.statusLabel,
    required this.pickup,
    required this.orderValue,
    required this.deliveryFee,
    required this.collectCash,
    required this.pickupCodeRequired,
    this.dropoff,
    this.deliveryDistanceMetres,
    this.itemCount,
    this.items = const <OrderItem>[],
    this.customerNote,
    this.placedAt,
    this.readyAt,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  /// Sent as a string by the API. Kept as one rather than parsed to an int —
  /// it is only ever put back into a URL, and a value that does not fit an int
  /// would round-trip wrong for the sake of nothing.
  final String id;

  final String orderNumber;
  final OrderStatus status;

  /// The API's own English wording. Rendered only when [status] decodes to
  /// [OrderStatus.unknown]; otherwise the translated label wins.
  final String statusLabel;

  final OrderPickup pickup;

  /// Null until the order is this rider's. See [OrderDropoff].
  final OrderDropoff? dropoff;

  final int? deliveryDistanceMetres;
  final int? itemCount;
  final List<OrderItem> items;

  final double orderValue;
  final double deliveryFee;

  /// What to collect at the door: the full total for cash on delivery, zero
  /// when it was paid online. Getting this wrong costs the rider their own
  /// money, so it is shown plainly wherever the order is.
  final double collectCash;

  final bool pickupCodeRequired;
  final String? customerNote;

  final DateTime? placedAt;
  final DateTime? readyAt;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  bool get isCashOnDelivery => collectCash > 0;

  /// The rider's own take on this job.
  double get earnings => deliveryFee;

  /// True while the API will still accept a hand-back.
  bool get canRelease => status.isActive && !status.isCollected;

  /// True once the merchant's code is the only thing left between the rider
  /// and the road.
  bool get awaitingPickup => status == OrderStatus.assigned;

  static RiderOrder fromJson(Map<String, dynamic> json) {
    final Object? pickup = json['pickup'];
    final Object? dropoff = json['dropoff'];

    return RiderOrder(
      // `id` is documented as a string but Laravel will happily send the
      // integer key, so it is normalised here rather than at every call site
      // that builds a URL from it.
      id: nullableString(json['id']) ?? '',
      orderNumber: nullableString(json['order_number']) ?? '',
      status: OrderStatus.fromWire(json['status']),
      statusLabel: nullableString(json['status_label']) ?? '',
      pickup: pickup is Map<String, dynamic>
          ? OrderPickup.fromJson(pickup)
          : const OrderPickup(address: ''),
      dropoff:
          dropoff is Map<String, dynamic> ? OrderDropoff.fromJson(dropoff) : null,
      // Documented as a string on the resource — it is a cast decimal, like
      // `rating` on the profile — so it goes through the same tolerant parse
      // as the numbers that arrive as numbers.
      deliveryDistanceMetres: _nullableInt(json['delivery_distance_metres']),
      itemCount: _nullableInt(json['item_count']),
      items: <OrderItem>[
        for (final Object? raw
            in json['items'] as List<Object?>? ?? const <Object?>[])
          if (raw is Map<String, dynamic>) OrderItem.fromJson(raw),
      ],
      orderValue: _num(json['order_value']),
      deliveryFee: _num(json['delivery_fee']),
      collectCash: _num(json['collect_cash']),
      pickupCodeRequired: json['pickup_code_required'] as bool? ?? false,
      customerNote: nullableString(json['customer_note']),
      placedAt: DateTime.tryParse('${json['placed_at']}'),
      readyAt: DateTime.tryParse('${json['ready_at']}'),
      assignedAt: DateTime.tryParse('${json['assigned_at']}'),
      pickedUpAt: DateTime.tryParse('${json['picked_up_at']}'),
      deliveredAt: DateTime.tryParse('${json['delivered_at']}'),
    );
  }
}

/// `GET /v1/rider/orders/available` — the list plus why it might be empty.
@immutable
class OrderBoard {
  const OrderBoard({required this.orders, required this.availability});

  final List<RiderOrder> orders;

  /// `meta.can_accept`. The empty state reads this, not the list length.
  final BoardAvailability availability;

  static const OrderBoard empty = OrderBoard(
    orders: <RiderOrder>[],
    availability: BoardAvailability.unknown,
  );

  bool get isEmpty => orders.isEmpty;

  static OrderBoard fromJson(Map<String, dynamic> json) {
    final Object? meta = json['meta'];
    return OrderBoard(
      orders: <RiderOrder>[
        for (final Object? raw
            in json['data'] as List<Object?>? ?? const <Object?>[])
          if (raw is Map<String, dynamic>) RiderOrder.fromJson(raw),
      ],
      availability: BoardAvailability.fromWire(
        meta is Map<String, dynamic> ? meta['can_accept'] : null,
      ),
    );
  }
}

double _num(Object? raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse('$raw') ?? 0;
}

double? _nullableNum(Object? raw) {
  if (raw is num) return raw.toDouble();
  final String? text = nullableString(raw);
  return text == null ? null : double.tryParse(text);
}

int _int(Object? raw) => raw is int ? raw : int.tryParse('$raw') ?? 0;

int? _nullableInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.round();
  final String? text = nullableString(raw);
  if (text == null) return null;
  return int.tryParse(text) ?? double.tryParse(text)?.round();
}
