import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/info_tile.dart';
import '../../../../../generated/l10n/app_localizations.dart';
import '../../../data/order_models.dart';
import '../order_formatting.dart';

/// One order, as it appears on the board and in the history list.
///
/// The three things a rider decides on — how far, what they earn, and whether
/// there is cash to handle — sit on one line above the button, because that
/// decision is made in about a second with a helmet still on.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onTap,
    this.isBusy = false,
  });

  final RiderOrder order;

  /// Null in the history list, where there is nothing left to accept.
  final VoidCallback? onAccept;

  final VoidCallback? onTap;

  /// True while any order action is in flight. Every accept button on the
  /// board goes inert together — a rider who taps two cards in the same second
  /// should take one order, not race themselves.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final String? distance =
        formatDistance(l10n, order.pickup.distanceMetres);

    final BorderRadius radius = BorderRadius.circular(AppTheme.radiusLarge);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.orderNumberLabel(order.orderNumber),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(
                      label: order.statusText(l10n),
                      tone: order.statusTone,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _AddressRow(
                  icon: Icons.storefront_outlined,
                  label: l10n.pickupLabel,
                  name: order.pickup.name,
                  address: order.pickup.address,
                  trailing: distance,
                ),
                if (order.dropoff != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _AddressRow(
                    icon: Icons.location_on_outlined,
                    label: l10n.dropoffLabel,
                    name: order.dropoff!.contactName,
                    address: order.dropoff!.address,
                    trailing: formatDistance(
                      l10n,
                      order.deliveryDistanceMetres,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Divider(color: theme.colorScheme.outline, height: 1),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _Figure(
                        label: l10n.earningsLabel,
                        value: formatAmount(l10n, order.earnings),
                        emphasis: true,
                      ),
                    ),
                    Expanded(
                      child: _Figure(
                        label: order.isCashOnDelivery
                            ? l10n.collectCashLabel
                            : l10n.prepaidLabel,
                        value: order.isCashOnDelivery
                            ? formatAmount(l10n, order.collectCash)
                            : null,
                        // Cash is the one figure on this card that can cost the
                        // rider their own money, so it is the one that gets a
                        // colour rather than blending into the row.
                        colour: order.isCashOnDelivery
                            ? AppColors.orangeDeep
                            : null,
                      ),
                    ),
                    if (order.itemCount != null)
                      Expanded(
                        child: _Figure(
                          label: '',
                          value: l10n.itemCount(order.itemCount!),
                        ),
                      ),
                  ],
                ),
                if (onAccept != null) ...<Widget>[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isBusy ? null : onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            isDark ? AppColors.greenLight : AppColors.greenDeep,
                      ),
                      child: Text(
                        l10n.acceptOrder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.icon,
    required this.label,
    required this.address,
    this.name,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? name;
  final String address;

  /// The distance, when there is one.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.greenLight : AppColors.greenDeep,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              if (name != null && name!.isNotEmpty)
                Text(
                  name!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Text(
                address,
                // Two lines, then ellipsis. A full address is three or four
                // lines in most Indian cities and would push the fee and the
                // accept button off a small screen — the details screen is
                // where the whole thing belongs.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 10),
          Text(
            trailing!,
            textDirection: TextDirection.ltr,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// A caption over a number, shrinking rather than wrapping.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.colour,
    this.emphasis = false,
  });

  final String label;

  /// Null renders the label alone, which is how "Paid online" reads — there is
  /// no amount to show, and a zero would be read as an amount.
  final String? value;

  final Color? colour;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color resolved = colour ??
        (emphasis
            ? (isDark ? AppColors.greenLight : AppColors.greenDeep)
            : theme.colorScheme.onSurface);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label.isNotEmpty)
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value ?? '—',
            maxLines: 1,
            textDirection: value == null ? null : TextDirection.ltr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: value == null ? theme.colorScheme.onSurfaceVariant : resolved,
            ),
          ),
        ),
      ],
    );
  }
}
