import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../data/navigation_models.dart';
import '../../data/order_models.dart';
import '../../state/navigation_controller.dart';
import '../../state/order_controller.dart';
import '../orders/order_formatting.dart';
import '../orders/widgets/contact_actions.dart';
import 'nav_map.dart';

/// Turn-by-turn to the restaurant or the customer, without leaving the app.
///
/// The screen is three bands, read top to bottom at a glance from a phone on
/// a handlebar mount: the next turn and how far it is, the road, and how long
/// is left. Everything a rider needs while moving is in the top band, in type
/// big enough to read without slowing down. The screen stays awake for as
/// long as it is open.
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({
    super.key,
    required this.order,
    required this.target,
  });

  final RiderOrder order;
  final NavTarget target;

  /// Opens navigation for [target], when the order has coordinates for it.
  static Future<void> open(
    BuildContext context,
    RiderOrder order,
    NavTarget target,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NavigationScreen(order: order, target: target),
      ),
    );
  }

  /// Whether [target] on [order] has a point to navigate to.
  static bool canNavigate(RiderOrder order, NavTarget target) =>
      _destinationOf(order, target) != null;

  static LatLng? _destinationOf(RiderOrder order, NavTarget target) {
    switch (target) {
      case NavTarget.pickup:
        final OrderPickup p = order.pickup;
        return p.hasCoordinates ? LatLng(p.latitude!, p.longitude!) : null;
      case NavTarget.dropoff:
        final OrderDropoff? d = order.dropoff;
        return d != null && d.hasCoordinates
            ? LatLng(d.latitude!, d.longitude!)
            : null;
    }
  }

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  late final LatLng _destination =
      NavigationScreen._destinationOf(widget.order, widget.target)!;

  late final NavigationController _nav = context.read<OrderController>().navigate(
        widget.order,
        target: widget.target,
        destination: _destination,
      )..start();

  /// False once the rider pans the map to look ahead; the recentre button
  /// brings the camera back behind them.
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    // A sat-nav that lets the screen sleep is useless. Best effort: a
    // platform without the plugin just behaves as before.
    unawaited(WakelockPlus.enable().catchError((Object _) {}));
  }

  @override
  void dispose() {
    unawaited(WakelockPlus.disable().catchError((Object _) {}));
    _nav.dispose();
    super.dispose();
  }

  String get _placeName => widget.target == NavTarget.pickup
      ? (widget.order.pickup.name ?? widget.order.pickup.address)
      : (widget.order.dropoff?.contactName ?? '');

  String get _placeAddress => widget.target == NavTarget.pickup
      ? widget.order.pickup.address
      : (widget.order.dropoff?.address ?? '');

  String? get _placePhone => widget.target == NavTarget.pickup
      ? widget.order.pickup.phone
      : widget.order.dropoff?.contactPhone;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);

    return ChangeNotifierProvider<NavigationController>.value(
      value: _nav,
      child: Consumer<NavigationController>(
        builder: (BuildContext context, NavigationController nav, _) {
          return Scaffold(
            body: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Listener(
                    onPointerDown: (_) {
                      if (_follow) setState(() => _follow = false);
                    },
                    child: NavMap(
                      here: nav.here,
                      heading: nav.position?.headingDegrees,
                      destination: _destination,
                      target: widget.target,
                      path: nav.path,
                      along: nav.along,
                      follow: _follow,
                      padding: EdgeInsets.only(
                        top: media.padding.top + 140,
                        bottom: 190 + media.padding.bottom,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: media.padding.top + 8,
                  left: 12,
                  right: 12,
                  child: _TurnBanner(nav: nav, placeName: _placeName),
                ),
                Positioned(
                  right: 16,
                  bottom: 196 + media.padding.bottom,
                  child: AnimatedScale(
                    scale: _follow ? 0 : 1,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: FloatingActionButton.extended(
                      heroTag: 'nav-recentre',
                      onPressed: () => setState(() => _follow = true),
                      icon: const Icon(Icons.navigation_rounded),
                      label: Text(AppLocalizations.of(context).navRecentre),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _TripPanel(
                    nav: nav,
                    target: widget.target,
                    placeName: _placeName,
                    placeAddress: _placeAddress,
                    phone: _placePhone,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The next turn: maneuver, distance, street, and a preview of the turn after.
class _TurnBanner extends StatelessWidget {
  const _TurnBanner({required this.nav, required this.placeName});

  final NavigationController nav;
  final String placeName;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    final (Color colour, IconData icon, String headline, String? detail) =
        _content(l10n);
    final NavStep? after = nav.turnAfter;
    final bool showThen = !nav.hasArrived &&
        nav.path != null &&
        after != null &&
        after.instruction.isNotEmpty;

    return Material(
      color: colour,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: <Widget>[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (Widget child, Animation<double> a) =>
                        ScaleTransition(scale: a, child: child),
                    child: Icon(
                      icon,
                      key: ValueKey<IconData>(icon),
                      size: 46,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          headline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (detail != null && detail.isNotEmpty)
                          Text(
                            detail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (nav.isRouting)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (showThen)
              Container(
                width: double.infinity,
                color: Colors.black.withValues(alpha: 0.16),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 9),
                child: Row(
                  children: <Widget>[
                    Icon(
                      maneuverIcon(after.maneuver),
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.navThen(after.instruction),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  (Color, IconData, String, String?) _content(AppLocalizations l10n) {
    if (nav.locationDenial != null) {
      return (
        AppColors.slate,
        Icons.location_off_rounded,
        l10n.navLocationOff,
        null,
      );
    }
    if (nav.hasArrived) {
      return (
        AppColors.greenDeep,
        Icons.where_to_vote_rounded,
        l10n.navArrived,
        l10n.navArrivedAt(placeName),
      );
    }
    final double? toTurn = nav.distanceToTurn;
    if (nav.here == null || toTurn == null) {
      return (
        AppColors.slate,
        Icons.gps_not_fixed_rounded,
        l10n.navFindingLocation,
        null,
      );
    }
    final String distance = formatDistance(l10n, _round(toTurn))!;

    if (nav.path == null) {
      return (
        AppColors.slate,
        Icons.near_me_rounded,
        distance,
        nav.isRouting ? l10n.navFindingRoute : l10n.navHeadTowards(placeName),
      );
    }

    final NavStep? turn = nav.nextTurn;
    if (turn == null) {
      // No turns left: the stop is straight ahead.
      return (
        AppColors.greenDeep,
        Icons.flag_rounded,
        distance,
        placeName,
      );
    }
    return (
      AppColors.greenDeep,
      maneuverIcon(turn.maneuver),
      distance,
      turn.instruction,
    );
  }

  /// Rounded the way a sat-nav announces it: to 10 m close in, 50 m further
  /// out. "In 237 m" is precision nobody can ride to.
  static int _round(double metres) {
    if (metres < 100) return (metres / 10).round() * 10;
    if (metres < 1000) return (metres / 50).round() * 50;
    return metres.round();
  }
}

/// ETA, distance, the stop, and the two buttons a rider needs mid-ride.
class _TripPanel extends StatelessWidget {
  const _TripPanel({
    required this.nav,
    required this.target,
    required this.placeName,
    required this.placeAddress,
    required this.phone,
  });

  final NavigationController nav;
  final NavTarget target;
  final String placeName;
  final String placeAddress;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Duration? left = nav.remainingTime;
    final double? metres = nav.remainingMetres;

    final String? eta = left == null
        ? null
        : l10n.navMinutes('${(left.inSeconds / 60).ceil().clamp(1, 999)}');
    final String? summary = metres == null
        ? null
        : left == null
            ? formatDistance(l10n, metres.round())
            : l10n.navRemaining(
                formatDistance(l10n, metres.round())!,
                MaterialLocalizations.of(context).formatTimeOfDay(
                  TimeOfDay.fromDateTime(DateTime.now().add(left)),
                ),
              );

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      target == NavTarget.pickup
                          ? l10n.navToRestaurant
                          : l10n.navToCustomer,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.greenDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        eta ?? summary ?? '—',
                        key: ValueKey<String?>(eta ?? summary),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (eta != null && summary != null)
                      Text(
                        summary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (phone != null && phone!.isNotEmpty) ...<Widget>[
                IconButton.filledTonal(
                  tooltip: target == NavTarget.pickup
                      ? l10n.callRestaurant
                      : l10n.callCustomer,
                  onPressed: () => dial(phone!),
                  style: IconButton.styleFrom(fixedSize: const Size.square(52)),
                  icon: const Icon(Icons.call_rounded),
                ),
                const SizedBox(width: 10),
              ],
              IconButton.filled(
                tooltip: l10n.navEnd,
                onPressed: () => Navigator.of(context).maybePop(),
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(52),
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(
                target == NavTarget.pickup
                    ? Icons.storefront_outlined
                    : Icons.location_on_outlined,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  placeAddress.isEmpty ? placeName : '$placeName · $placeAddress',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (nav.routeUnavailable && !nav.hasArrived) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              l10n.navNoRoute,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (nav.hasArrived) ...<Widget>[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.greenDeep,
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text(l10n.navArrived),
            ),
          ],
        ],
      ),
    );
  }
}

/// The icon for a turn, from Material's own navigation set.
IconData maneuverIcon(Maneuver maneuver) => switch (maneuver) {
      Maneuver.turnLeft => Icons.turn_left_rounded,
      Maneuver.turnRight => Icons.turn_right_rounded,
      Maneuver.slightLeft => Icons.turn_slight_left_rounded,
      Maneuver.slightRight => Icons.turn_slight_right_rounded,
      Maneuver.sharpLeft => Icons.turn_sharp_left_rounded,
      Maneuver.sharpRight => Icons.turn_sharp_right_rounded,
      Maneuver.uTurnLeft => Icons.u_turn_left_rounded,
      Maneuver.uTurnRight => Icons.u_turn_right_rounded,
      Maneuver.roundaboutLeft => Icons.roundabout_left_rounded,
      Maneuver.roundaboutRight => Icons.roundabout_right_rounded,
      Maneuver.forkLeft => Icons.fork_left_rounded,
      Maneuver.forkRight => Icons.fork_right_rounded,
      Maneuver.rampLeft => Icons.ramp_left_rounded,
      Maneuver.rampRight => Icons.ramp_right_rounded,
      Maneuver.merge => Icons.merge_rounded,
      Maneuver.arrive => Icons.flag_rounded,
      Maneuver.depart || Maneuver.straight => Icons.straight_rounded,
    };
