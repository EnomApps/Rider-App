import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/info_tile.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../data/order_models.dart';
import '../../state/order_controller.dart';
import 'active_delivery_screen.dart' show OrderItemList;
import 'order_formatting.dart';
import 'widgets/contact_actions.dart';

/// One order in full.
///
/// Opened from the board, where the card carries only what a rider needs to
/// decide, and from history, where the card carries only what they need to
/// recognise it. Either way this screen fills in the rest.
///
/// It renders the order it was handed immediately and refetches in the
/// background. A board entry is a partial resource — no items, no drop
/// address — so the refetch is what completes it, and showing the partial
/// version meanwhile beats a spinner over data already in hand.
class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.order});

  final RiderOrder order;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late RiderOrder _order = widget.order;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);

    final RiderOrder? fresh =
        await context.read<OrderController>().orderDetails(widget.order.id);

    if (!mounted) return;
    setState(() {
      // A failed refetch leaves what was already on screen. The board entry
      // does not stop being true because one request missed.
      if (fresh != null) _order = fresh;
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RiderOrder order = _order;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderDetailsTitle),
        bottom: _isRefreshing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.orderNumberLabel(order.orderNumber),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(
                  label: order.statusText(l10n),
                  tone: order.statusTone,
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: <Widget>[
                Expanded(
                  child: _Money(
                    label: l10n.earningsLabel,
                    value: formatAmount(l10n, order.earnings),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Money(
                    label: order.isCashOnDelivery
                        ? l10n.collectCashLabel
                        : l10n.prepaidLabel,
                    value: order.isCashOnDelivery
                        ? formatAmount(l10n, order.collectCash)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _Place(
              icon: Icons.storefront_outlined,
              label: l10n.pickupLabel,
              name: order.pickup.name,
              address: order.pickup.address,
              distance: formatDistance(l10n, order.pickup.distanceMetres),
              actions: ContactActions(
                callLabel: l10n.callRestaurant,
                directionsLabel: l10n.openInMaps,
                phone: order.pickup.phone,
                latitude: order.pickup.latitude,
                longitude: order.pickup.longitude,
                address: order.pickup.address,
              ),
            ),

            if (order.dropoff != null) ...<Widget>[
              const SizedBox(height: 14),
              _Place(
                icon: Icons.location_on_outlined,
                label: l10n.dropoffLabel,
                name: order.dropoff!.contactName,
                address: order.dropoff!.address,
                distance: formatDistance(l10n, order.deliveryDistanceMetres),
                actions: ContactActions(
                  callLabel: l10n.callCustomer,
                  directionsLabel: l10n.openInMaps,
                  phone: order.dropoff!.contactPhone,
                  latitude: order.dropoff!.latitude,
                  longitude: order.dropoff!.longitude,
                  address: order.dropoff!.address,
                ),
              ),
            ],

            if (order.customerNote != null) ...<Widget>[
              const SizedBox(height: 14),
              InfoTile(
                icon: Icons.sticky_note_2_outlined,
                label: l10n.customerNoteLabel,
                value: order.customerNote!,
              ),
            ],

            if (order.items.isNotEmpty) ...<Widget>[
              const SizedBox(height: 22),
              Text(
                l10n.orderItemsLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              OrderItemList(items: order.items),
            ],

            const SizedBox(height: 22),
            _Timeline(order: order),
          ],
        ),
      ),
    );
  }
}

class _Money extends StatelessWidget {
  const _Money({required this.label, required this.value});

  final String label;

  /// Null means there is no amount — "Paid online". A zero here would read as
  /// an amount to collect.
  final String? value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value ?? '—',
              maxLines: 1,
              textDirection: value == null ? null : TextDirection.ltr,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: value == null
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Place extends StatelessWidget {
  const _Place({
    required this.icon,
    required this.label,
    required this.address,
    required this.actions,
    this.name,
    this.distance,
  });

  final IconData icon;
  final String label;
  final String? name;
  final String address;
  final String? distance;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (name != null && name!.isNotEmpty)
                      Text(
                        name!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(address, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              if (distance != null) ...<Widget>[
                const SizedBox(width: 10),
                Text(
                  distance!,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          actions,
        ],
      ),
    );
  }
}

/// The stamps the API returns, in the order they happened.
///
/// Only the ones that exist are drawn: an order still at the counter has no
/// delivery time, and a row of empty dashes would read as missing data rather
/// than as a step not yet reached.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});

  final RiderOrder order;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    final List<(String, DateTime)> stamps = <(String, DateTime)>[
      if (order.placedAt != null) (l10n.orderPreparing, order.placedAt!),
      if (order.readyAt != null) (l10n.orderReadyForPickup, order.readyAt!),
      if (order.assignedAt != null) (l10n.orderAssigned, order.assignedAt!),
      if (order.pickedUpAt != null) (l10n.orderPickedUp, order.pickedUpAt!),
      if (order.deliveredAt != null) (l10n.orderDelivered, order.deliveredAt!),
    ];

    if (stamps.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: <Widget>[
          for (final (String label, DateTime at) in stamps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label, style: theme.textTheme.bodyMedium),
                  ),
                  Text(
                    formatTime(context, at),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
