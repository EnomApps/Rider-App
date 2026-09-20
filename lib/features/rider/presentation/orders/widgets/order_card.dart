import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_surface.dart';
import '../../../../../core/widgets/info_tile.dart';
import '../../../../../generated/l10n/app_localizations.dart';
import '../../../data/order_models.dart';
import '../order_formatting.dart';

/// One order, as it appears on the board and in the history list.
///
/// Laid out as a decision, in the order the decision is made: which shop and
/// how far, then what it pays and whether there is cash to handle, then the
/// button. That is about a second's reading with a helmet still on.
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

    return SurfaceCard(
      radius: AppSurface.radiusLarge,
      onTap: onTap,
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
                    letterSpacing: -0.1,
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
          const SizedBox(height: 16),

          // Drawn as one journey joined by a rail rather than two unrelated
          // rows. A rider reads a delivery as a route, and on the board the
          // second stop is deliberately missing — which the rail then shows as
          // an open end instead of hiding.
          _Route(
            pickupLabel: l10n.pickupLabel,
            pickupName: order.pickup.name,
            pickupAddress: order.pickup.address,
            pickupTrailing: formatDistance(l10n, order.pickup.distanceMetres),
            dropoffLabel: order.dropoff == null ? null : l10n.dropoffLabel,
            dropoffName: order.dropoff?.contactName,
            dropoffAddress: order.dropoff?.address,
            dropoffTrailing: order.dropoff == null
                ? null
                : formatDistance(l10n, order.deliveryDistanceMetres),
          ),

          const SizedBox(height: 16),
          Divider(color: AppSurface.line(context), height: 1),
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
                  // Cash is the one figure here that can cost the rider their
                  // own money, so it is the one that gets a colour rather than
                  // blending into the row.
                  colour: order.isCashOnDelivery ? AppColors.orangeDeep : null,
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
              child: FilledButton.icon(
                onPressed: isBusy ? null : onAccept,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.greenLight : AppColors.greenDeep,
                  foregroundColor:
                      isDark ? const Color(0xFF10250A) : AppColors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: const Icon(Icons.bolt_rounded, size: 20),
                label: Text(
                  l10n.acceptOrder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pickup and drop-off, joined by a vertical rail.
///
/// The rail is the point: it turns two addresses into a journey with a
/// direction. On the board the drop-off is withheld by the API, so the rail
/// ends in a hollow marker — the shape says "there is a second stop, you will
/// see it when it is yours" rather than leaving a gap.
class _Route extends StatelessWidget {
  const _Route({
    required this.pickupLabel,
    required this.pickupAddress,
    this.pickupName,
    this.pickupTrailing,
    this.dropoffLabel,
    this.dropoffName,
    this.dropoffAddress,
    this.dropoffTrailing,
  });

  final String pickupLabel;
  final String? pickupName;
  final String pickupAddress;
  final String? pickupTrailing;

  final String? dropoffLabel;
  final String? dropoffName;
  final String? dropoffAddress;
  final String? dropoffTrailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color start = isDark ? AppColors.greenLight : AppColors.greenDeep;
    final Color end = AppColors.orangeDeep;
    final bool hasDropoff = dropoffAddress != null;

    // IntrinsicHeight is what lets the rail stretch to exactly the height of
    // the two stops beside it. Inside a scroll view the row's cross axis is
    // unbounded, so the rail's `Expanded` has nothing to expand into and the
    // layout throws. Measuring the text column first is the cost of drawing a
    // line whose length is decided by content it does not own.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // The rail sits in its own column so both stops share one continuous
          // line rather than each drawing half of it.
          SizedBox(
            width: 18,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 3),
                _Marker(colour: start, filled: true),
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          start.withValues(alpha: 0.55),
                          (hasDropoff ? end : start).withValues(alpha: 0.22),
                        ],
                      ),
                    ),
                  ),
                ),
                _Marker(colour: hasDropoff ? end : start, filled: hasDropoff),
                const SizedBox(height: 3),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Stop(
                  label: pickupLabel,
                  name: pickupName,
                  address: pickupAddress,
                  trailing: pickupTrailing,
                ),
                const SizedBox(height: 14),
                if (hasDropoff)
                  _Stop(
                    label: dropoffLabel!,
                    name: dropoffName,
                    address: dropoffAddress!,
                    trailing: dropoffTrailing,
                  )
                else
                  // Not an error state and not a placeholder to be filled in
                  // later — the address genuinely does not exist for this
                  // rider yet, and saying so is more use than a blank.
                  Text(
                    AppLocalizations.of(context).dropoffLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
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

class _Marker extends StatelessWidget {
  const _Marker({required this.colour, required this.filled});

  final Color colour;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? colour : Colors.transparent,
        border: Border.all(
          color: colour.withValues(alpha: filled ? 1 : 0.5),
          width: 2,
        ),
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.label,
    required this.address,
    this.name,
    this.trailing,
  });

  final String label;
  final String? name;
  final String address;

  /// The distance, when the API sent one.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
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
                // Two lines, then ellipsis. A full address runs three or four
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              trailing!,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
              letterSpacing: -0.3,
              color:
                  value == null ? theme.colorScheme.onSurfaceVariant : resolved,
            ),
          ),
        ),
      ],
    );
  }
}
