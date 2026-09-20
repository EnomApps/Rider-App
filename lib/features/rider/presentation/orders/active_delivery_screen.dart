import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/motion/app_motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_surface.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/info_tile.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../data/order_models.dart';
import '../../data/rider_failure.dart';
import '../../state/order_controller.dart';
import '../../state/rider_controller.dart';
import 'order_formatting.dart';
import 'widgets/contact_actions.dart';
import 'widgets/order_empty_state.dart';
import 'widgets/pickup_code_sheet.dart';
import 'widgets/release_order_sheet.dart';

/// The order in hand, and the one thing to do about it next.
///
/// Structured around a single primary button that changes meaning with the
/// order's status — collect, then deliver — rather than a screen of options.
/// A rider reads this at a counter or on a doorstep, usually one-handed, and
/// the question is always "what now?", never "which of these?".
///
/// The status comes from the server on every action, never guessed locally: an
/// order this app thinks is picked up but the API does not would leave the
/// rider pressing Delivered on something that will 422.
class ActiveDeliveryScreen extends StatelessWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OrderController orders = context.watch<OrderController>();
    final RiderOrder? order = orders.active;

    if (order == null) {
      return RefreshIndicator(
        onRefresh: () => orders.loadActive(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            if (orders.isLoadingActive)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              OrderEmptyState(
                icon: Icons.inbox_outlined,
                title: l10n.noActiveDeliveryTitle,
                body: l10n.noActiveDeliveryBody,
              ),
          ],
        ),
      );
    }

    final bool collected = order.status.isCollected;

    return RefreshIndicator(
      onRefresh: () => orders.loadActive(silent: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
          const SizedBox(height: 10),
          // Two stages, and which one the rider is in. The whole screen is
          // "what now?", so answering it above the fold — before the cash, the
          // addresses or the ticket — is the point.
          _StageStrip(collected: collected),
          const SizedBox(height: 18),

          // Cash first, above the addresses. It is the one number on this
          // screen the rider is personally liable for, and burying it under a
          // list of items is how a prepaid order gets charged twice.
          _CashBanner(order: order),
          const SizedBox(height: 16),

          _Leg(
            icon: Icons.storefront_outlined,
            label: l10n.pickupLabel,
            name: order.pickup.name,
            address: order.pickup.address,
            distance: formatDistance(l10n, order.pickup.distanceMetres),
            // Once the food is collected the restaurant is behind the rider —
            // showing it as the live leg would point them the wrong way.
            dimmed: collected,
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
            _Leg(
              icon: Icons.location_on_outlined,
              label: l10n.dropoffLabel,
              name: order.dropoff!.contactName,
              address: order.dropoff!.address,
              distance: formatDistance(l10n, order.deliveryDistanceMetres),
              dimmed: !collected,
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
            _Note(note: order.customerNote!),
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

          const SizedBox(height: 26),
          _PrimaryAction(order: order),

          if (order.canRelease) ...<Widget>[
            const SizedBox(height: 12),
            TextButton(
              onPressed: orders.isActing
                  ? null
                  : () => _release(context, order.id),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(
                l10n.releaseOrderButton,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> _release(BuildContext context, String orderId) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    final bool released = await ReleaseOrderSheet.show(context, orderId);
    if (!released) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.orderReleased)));
  }
}

/// The single button that moves the order along.
///
/// Two states only, because there are only ever two things left to do: collect
/// it, or hand it over. Anything else — a release, a call — is secondary and
/// sits below or beside the address it belongs to.
class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.order});

  final RiderOrder order;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OrderController orders = context.watch<OrderController>();

    if (order.status.isCollected) {
      return GradientButton(
        label: l10n.confirmDeliveryButton,
        icon: Icons.check_rounded,
        onPressed: orders.isActing ? null : () => _deliver(context),
      );
    }

    return GradientButton(
      label: l10n.confirmPickupButton,
      icon: Icons.qr_code_2_rounded,
      onPressed: orders.isActing
          ? null
          : () async {
              final ScaffoldMessengerState messenger =
                  ScaffoldMessenger.of(context);
              final AppLocalizations strings = AppLocalizations.of(context);

              final bool confirmed =
                  await PickupCodeSheet.show(context, order.id);
              if (!confirmed) return;

              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(strings.pickupConfirmed)),
                );
            },
    );
  }

  /// Confirming a delivery is irreversible and, on a cash order, is the moment
  /// the rider becomes liable for the money. So it asks first — and the
  /// question names the amount, because "did you collect it?" is easier to wave
  /// through than "did you collect ₹480?".
  Future<void> _deliver(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OrderController orders = context.read<OrderController>();
    final RiderController rider = context.read<RiderController>();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.confirmDeliveryTitle),
        content: Text(
          order.isCashOnDelivery
              ? l10n.confirmDeliveryCashBody(
                  formatAmount(l10n, order.collectCash),
                )
              : l10n.confirmDeliveryBody,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirmDeliveryButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final RiderFailure? failure = await orders.deliver(order.id);

    if (failure == null) {
      // The server increments `completed_deliveries` and puts the rider back
      // on `available`. Refetching is how the home screen learns both — adding
      // one locally would drift from the figure the rider is paid against.
      await rider.refresh();
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure == null ? l10n.deliveryConfirmed : failure.message(l10n),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
  }
}

/// What to collect at the door, or plainly that there is nothing to collect.
///
/// Both cases get a banner. A prepaid order with no banner at all leaves the
/// rider to infer it, and the failure mode of inferring wrong is asking a
/// customer for money they have already paid.
class _CashBanner extends StatelessWidget {
  const _CashBanner({required this.order});

  final RiderOrder order;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool cash = order.isCashOnDelivery;

    final Color base = cash
        ? AppColors.orangeDeep
        : (isDark ? AppColors.greenLight : AppColors.greenDeep);

    return SurfaceCard(
      accent: base,
      padding: const EdgeInsets.all(17),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: base.withValues(alpha: isDark ? 0.24 : 0.16),
            ),
            child: Icon(
              cash ? Icons.payments_rounded : Icons.verified_rounded,
              color: base,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              cash
                  ? l10n.collectAtDoor(formatAmount(l10n, order.collectCash))
                  : l10n.nothingToCollect,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: base,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One half of the journey — the restaurant, or the customer.
class _Leg extends StatelessWidget {
  const _Leg({
    required this.icon,
    required this.label,
    required this.address,
    required this.actions,
    this.name,
    this.distance,
    this.dimmed = false,
  });

  final IconData icon;
  final String label;
  final String? name;
  final String address;
  final String? distance;
  final Widget actions;

  /// True for the leg that is behind the rider. Kept on screen rather than
  /// removed — a rider who has to go back for a forgotten item still needs the
  /// restaurant's number.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color accent = isDark ? AppColors.greenLight : AppColors.greenDeep;

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.change,
        padding: const EdgeInsets.all(18),
        decoration: AppSurface.decoration(
          context,
          accent: dimmed ? null : accent,
          radius: AppSurface.radiusLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(icon, size: 22, color: accent),
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
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.sticky_note_2_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.customerNoteLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(note, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// The ticket, as a checklist for the counter.
///
/// Quantity leads, then the dish, then its options — that is the order the bag
/// is checked in. The line total is present but quiet: the rider is confirming
/// contents, not settling a bill.
class OrderItemList extends StatelessWidget {
  const OrderItemList({super.key, required this.items});

  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, color: theme.colorScheme.outline),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${items[i].quantity}',
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            _VegMark(isVeg: items[i].isVeg),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                items[i].name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (items[i].options.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            items[i]
                                .options
                                .map((OrderItemOption o) => o.name)
                                .join(', '),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        if (items[i].notes != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            items[i].notes!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formatAmount(l10n, items[i].lineTotal),
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The green or brown square every Indian menu carries. Drawn rather than
/// translated: it is a regulatory mark, and it means the same thing in all 23
/// languages.
class _VegMark extends StatelessWidget {
  const _VegMark({required this.isVeg});

  final bool isVeg;

  @override
  Widget build(BuildContext context) {
    final Color colour =
        isVeg ? const Color(0xFF2C8B0D) : const Color(0xFF9B2C2C);

    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        border: Border.all(color: colour, width: 1.4),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Where the rider is in the two-step journey, and what is left.
///
/// Both stages are always shown, the finished one struck through in the
/// accent rather than hidden: a rider glancing down mid-ride wants to confirm
/// what they have already done as much as what is next.
class _StageStrip extends StatelessWidget {
  const _StageStrip({required this.collected});

  final bool collected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Row(
      children: <Widget>[
        Expanded(
          child: _Stage(
            label: l10n.headToRestaurant,
            icon: Icons.storefront_rounded,
            state: collected ? _StageState.done : _StageState.live,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Stage(
            label: l10n.deliverToCustomer,
            icon: Icons.location_on_rounded,
            state: collected ? _StageState.live : _StageState.waiting,
          ),
        ),
      ],
    );
  }
}

enum _StageState { done, live, waiting }

class _Stage extends StatelessWidget {
  const _Stage({
    required this.label,
    required this.icon,
    required this.state,
  });

  final String label;
  final IconData icon;
  final _StageState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color green = isDark ? AppColors.greenLight : AppColors.greenDeep;

    final Color tint = switch (state) {
      _StageState.done => green,
      _StageState.live => AppColors.orangeDeep,
      _StageState.waiting => theme.colorScheme.onSurfaceVariant,
    };

    final bool filled = state != _StageState.waiting;

    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.change,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: filled
            ? tint.withValues(alpha: isDark ? 0.16 : 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSurface.radiusSmall),
        border: Border.all(
          color: filled
              ? tint.withValues(alpha: 0.4)
              : AppSurface.line(context),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            state == _StageState.done ? Icons.check_rounded : icon,
            size: 17,
            color: tint,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tint,
                fontWeight: state == _StageState.live
                    ? FontWeight.w800
                    : FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
