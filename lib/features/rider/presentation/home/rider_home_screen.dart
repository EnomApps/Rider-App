import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/info_tile.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../auth/data/auth_user.dart';
import '../../../auth/state/auth_controller.dart';
import '../../data/kyc_models.dart';
import '../../data/order_models.dart';
import '../../data/rider_failure.dart';
import '../../data/rider_profile.dart';
import '../../state/order_controller.dart';
import '../../state/rider_controller.dart';
import '../orders/active_delivery_screen.dart';
import '../orders/delivery_history_screen.dart';
import '../orders/order_board_screen.dart';

/// The main UI, reached only when `can_go_online` is true.
///
/// A rider who has not been approved never sees this screen — the gate hands
/// them the wizard or the waiting room instead — so nothing here has to defend
/// against an unverified account. What it does defend against is the API
/// changing its mind mid-session: a licence that lapses while the rider is
/// online makes the next duty-status call fail, and the toggle reports that
/// rather than silently staying on.
///
/// Four tabs rather than a stack of pushed routes. A shift moves between them
/// constantly — accept on the board, work the delivery, back to the board —
/// and a route stack would have to be unwound on every transition, exactly as
/// it would at the gate above.
class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  /// The two tab indices anything else refers to. Named because several
  /// places bring the delivery tab forward, and a bare index repeated in each
  /// of them is one reorder away from pointing at the wrong screen.
  static const int _boardTab = 1;
  static const int _deliveryTab = 2;

  int _tab = 0;

  /// True once the arrival of an order has moved the rider to the delivery
  /// tab, so it happens on the transition rather than on every rebuild — a
  /// rider who deliberately walks back to the board should stay there.
  String? _announcedOrderId;

  /// Captured while mounted, because `dispose` cannot read from the context.
  OrderController? _orders;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resume());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orders = context.read<OrderController>();
  }

  /// The heartbeat belongs to this screen, so it ends with it.
  ///
  /// The gate above can replace the home screen mid-session — an approval
  /// lapsing, a licence expiring, a sign-out — and a ping timer that survived
  /// that would keep reporting a position for a rider the app has already
  /// stopped showing a shift to.
  @override
  void dispose() {
    _orders?.stopTracking();
    super.dispose();
  }

  /// Picks the shift back up: what the rider is carrying, and the position
  /// heartbeat if they are on duty.
  ///
  /// Both come from the server rather than from anything remembered locally.
  /// A shift outlives an app process, and an order accepted before a crash is
  /// still the rider's when they reopen.
  Future<void> _resume() async {
    if (!mounted) return;
    final OrderController orders = context.read<OrderController>();
    final RiderController rider = context.read<RiderController>();

    await orders.loadActive();
    if (!mounted) return;

    if (rider.profile?.dutyStatus == DutyStatus.available) {
      orders.startTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OrderController orders = context.watch<OrderController>();

    // An order that arrived while the rider was elsewhere brings the delivery
    // tab forward once. Done in the build rather than in a listener because it
    // is a consequence of the state, not of the event that produced it — an
    // order resumed after a restart deserves the same treatment as one just
    // accepted.
    final RiderOrder? active = orders.active;
    if (active != null && active.id != _announcedOrderId) {
      _announcedOrderId = active.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _tab = _deliveryTab);
      });
    } else if (active == null) {
      _announcedOrderId = null;
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const BrandMark(size: 36, radius: 11),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                l10n.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: l10n.profileTitle,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        // Kept alive rather than rebuilt: the board's poll timer and the
        // delivery screen's scroll position both belong to the shift, not to
        // whichever tab happens to be in front.
        index: _tab,
        children: <Widget>[
          _ShiftTab(onOpenDelivery: () => setState(() => _tab = _deliveryTab)),
          OrderBoardScreen(isActive: _tab == _boardTab),
          const ActiveDeliveryScreen(),
          const DeliveryHistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (int index) => setState(() => _tab = index),
        destinations: <Widget>[
          NavigationDestination(
            icon: const Icon(Icons.bolt_outlined),
            selectedIcon: const Icon(Icons.bolt_rounded),
            label: l10n.shiftTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt_rounded),
            label: l10n.ordersTab,
          ),
          NavigationDestination(
            // The dot is the whole point of the badge: a rider glancing down
            // needs to know they are carrying something, not how many.
            icon: Badge(
              isLabelVisible: orders.hasActiveOrder,
              child: const Icon(Icons.delivery_dining_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: orders.hasActiveOrder,
              child: const Icon(Icons.delivery_dining_rounded),
            ),
            label: l10n.deliveryTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history_rounded),
            label: l10n.historyTab,
          ),
        ],
      ),
    );
  }
}

/// The shift tab: who the rider is, whether they are working, and what that
/// has earned them so far.
class _ShiftTab extends StatelessWidget {
  const _ShiftTab({required this.onOpenDelivery});

  /// Brings the delivery tab forward. Passed down rather than reached for,
  /// so the card below does not have to know it lives inside a tab shell.
  final VoidCallback onOpenDelivery;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppLanguage language = context.watch<LocaleController>().language;
    final AuthUser? user = context.watch<AuthController>().user;
    final RiderController rider = context.watch<RiderController>();
    final OrderController orders = context.watch<OrderController>();
    final RiderProfile? profile = rider.profile;

    return RefreshIndicator(
      onRefresh: () async {
        await rider.refresh();
        await orders.loadActive(silent: true);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          if (user != null) ...<Widget>[
            Text(
              l10n.greetingNamed(
                profile?.fullName.isNotEmpty ?? false
                    ? profile!.fullName.split(' ').first
                    : user.firstName,
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(l10n.riderHomeTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(l10n.riderHomeSubtitle, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          if (profile != null) ...<Widget>[
            _DutyCard(profile: profile),
            const SizedBox(height: 16),
            if (orders.active != null) ...<Widget>[
              _ActiveOrderSummary(
                order: orders.active!,
                onTap: onOpenDelivery,
              ),
              const SizedBox(height: 16),
            ],
            _StatsRow(profile: profile),
            const SizedBox(height: 16),
            InfoTile(
              icon: Icons.two_wheeler_outlined,
              label: l10n.vehicleLabel,
              value: profile.vehicleNumber ?? l10n.notProvided,
              emphasise: profile.vehicleNumber != null,
              valueDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 12),
            InfoTile(
              icon: Icons.verified_user_outlined,
              label: l10n.kycStatusLabel,
              // The chip carries the status on its own; repeating it as the
              // value would put the same word in the row twice.
              value: '',
              trailing: StatusChip(
                label: _kycLabel(profile.kyc.status, l10n),
                tone: profile.kyc.status.isVerified
                    ? StatusTone.positive
                    : StatusTone.warning,
              ),
            ),
            const SizedBox(height: 12),
          ],
          InfoTile(
            icon: Icons.translate_rounded,
            label: l10n.appLanguageLabel,
            value: language.nativeName,
            valueDirection: language.textDirection,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.language,
              arguments: false,
            ),
          ),
        ],
      ),
    );
  }

  static String _kycLabel(KycStatus status, AppLocalizations l10n) {
    switch (status) {
      case KycStatus.verified:
        return l10n.kycVerified;
      case KycStatus.submitted:
        return l10n.kycSubmitted;
      case KycStatus.rejected:
        return l10n.kycRejected;
      case KycStatus.pending:
      case KycStatus.unknown:
        return l10n.kycPending;
    }
  }
}

/// A one-line reminder of the order in hand, on the tab that is not about it.
///
/// Tapping it goes to the delivery tab rather than pushing a screen, so there
/// is one place an order is worked and one back button that means what it
/// looks like.
class _ActiveOrderSummary extends StatelessWidget {
  const _ActiveOrderSummary({required this.order, required this.onTap});

  final RiderOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color accent = AppColors.orangeDeep;

    final BorderRadius radius = BorderRadius.circular(AppTheme.radiusLarge);

    return Material(
      color: accent.withValues(alpha: isDark ? 0.14 : 0.09),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: <Widget>[
                Icon(Icons.delivery_dining_rounded, color: accent, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        l10n.orderNumberLabel(order.orderNumber),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.status.isCollected
                            ? l10n.deliverToCustomer
                            : l10n.headToRestaurant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The one control that matters: online, on a break, or offline.
///
/// Three states rather than a switch, because the API has three and collapsing
/// `on_break` into "offline" would lose the distinction dispatch relies on —
/// a rider on a break is still working, just not receiving.
class _DutyCard extends StatelessWidget {
  const _DutyCard({required this.profile});

  final RiderProfile profile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RiderController rider = context.watch<RiderController>();
    final OrderController orders = context.watch<OrderController>();
    final bool isDark = theme.brightness == Brightness.dark;

    final bool online = profile.dutyStatus == DutyStatus.available;
    final bool onBreak = profile.dutyStatus == DutyStatus.onBreak;

    // Null whenever nothing is blocking, which is the ordinary case.
    final String? reason = rider.offlineReason;

    final Color accent = online
        ? (isDark ? AppColors.greenLight : AppColors.greenDeep)
        : onBreak
            ? AppColors.orange
            : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: online ? accent.withValues(alpha: 0.5) : theme.colorScheme.outline,
          width: online ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _Beacon(active: online, colour: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.dutyStatusLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      online
                          ? l10n.dutyOnline
                          : onBreak
                              ? l10n.dutyOnBreak
                              : l10n.dutyOffline,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              if (rider.isSaving)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            online ? l10n.waitingForOrders : l10n.youAreOffline,
            style: theme.textTheme.bodyMedium,
          ),

          // The server's own sentence, rendered as it arrived. It is the same
          // text the duty-status 403 carries, so a rider who taps the button
          // anyway is told exactly what this banner already said — one reason,
          // not two that have to be reconciled.
          if (!profile.canGoOnline && reason != null) ...<Widget>[
            const SizedBox(height: 12),
            _BlockedNotice(reason: reason),
          ],

          // Only shown while it is true, and only while online — a rider who
          // has clocked off should not be told their location is being shared.
          if (online && orders.isTracking) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Icon(
                  Icons.my_location_rounded,
                  size: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.trackingOn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  // `can_go_online` gates going on duty; clocking *off* is
                  // never blocked, so an offline-bound tap stays live even
                  // when something is wrong with the rider's papers.
                  onPressed: rider.isSaving || (!online && !profile.canGoOnline)
                      ? null
                      : () => _set(
                            context,
                            online ? DutyStatus.offline : DutyStatus.available,
                          ),
                  child: Text(online ? l10n.goOffline : l10n.goOnline),
                ),
              ),
              // Only offered while working — a break from being offline is not
              // a state the API models, and it would 422.
              if (online || onBreak) ...<Widget>[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    // Coming back from a break is going on duty, so it is
                    // blocked by the same verdict. Starting one never is.
                    onPressed:
                        rider.isSaving || (onBreak && !profile.canGoOnline)
                            ? null
                            : () => _set(
                                  context,
                                  onBreak
                                      ? DutyStatus.available
                                      : DutyStatus.onBreak,
                                ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                      ),
                    ),
                    child: Text(
                      onBreak ? l10n.goOnline : l10n.takeABreak,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// A 403 here is the API refusing to dispatch — a lapsed licence, most
  /// often. A 422 is the API refusing to let a rider clock off mid-delivery.
  /// Both are surfaced verbatim rather than swallowed, because they are the
  /// only warning the rider gets before a shift they cannot work.
  Future<void> _set(BuildContext context, DutyStatus status) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RiderController rider = context.read<RiderController>();
    final OrderController orders = context.read<OrderController>();

    final bool goingOnline = status == DutyStatus.available;

    // Asked for before the duty call, not after: the system dialog then
    // appears while the rider is still looking at the button they pressed,
    // and a refusal is caught before they are put on a board that cannot rank
    // them. A refusal does not block going online — dispatch simply has
    // nothing to sort by until a position arrives — so the failure is
    // reported and the call goes ahead.
    RiderFailure? locationFailure;
    if (goingOnline) locationFailure = await orders.primeLocation();

    final RiderFailure? failure = await rider.setDutyStatus(status);

    if (failure == null) {
      if (goingOnline) {
        orders.startTracking();
      } else if (status == DutyStatus.offline) {
        // A break still counts as working, so only a full clock-off stops the
        // heartbeat.
        orders.stopTracking();
      }
    }

    final RiderFailure? reported = failure ?? locationFailure;
    if (reported == null) return;

    // A refused duty change is the one place the server's own words win over
    // a translated string: it is the same sentence `offline_reason` carries,
    // and the banner above the button is already showing it.
    final String? verbatim =
        failure == RiderFailure.documentsExpired ||
                failure == RiderFailure.awaitingVerification
            ? rider.dutyRefusal
            : null;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(verbatim ?? reported.message(l10n)),
          duration: const Duration(seconds: 6),
        ),
      );
  }
}

/// The server's reason a rider cannot clock on, shown as it arrived.
///
/// Deliberately not translated. `offline_reason` and the duty-status 403 are
/// the same string, and a rider shown a translated banner over an untranslated
/// error — or the reverse — has to work out which of the two to believe. One
/// source, one wording. See README > Localisation.
class _BlockedNotice extends StatelessWidget {
  const _BlockedNotice({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    const Color base = AppColors.orangeDeep;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: base.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: base.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, size: 20, color: base),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing dot while online, flat while not. The one piece of motion on the
/// screen, so "am I receiving orders?" is answerable at a glance from a bike
/// mount.
class _Beacon extends StatefulWidget {
  const _Beacon({required this.active, required this.colour});

  final bool active;
  final Color colour;

  @override
  State<_Beacon> createState() => _BeaconState();
}

class _BeaconState extends State<_Beacon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(_Beacon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, _) {
          final double t = _c.value;
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (widget.active)
                Container(
                  width: 10 + 12 * t,
                  height: 10 + 12 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.colour.withValues(alpha: 0.30 * (1 - t)),
                  ),
                ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.colour,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});

  final RiderProfile profile;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Row(
      children: <Widget>[
        Expanded(
          child: _StatTile(
            icon: Icons.local_shipping_outlined,
            label: l10n.completedDeliveriesLabel,
            value: '${profile.completedDeliveries}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.star_outline_rounded,
            label: l10n.ratingLabel,
            value: profile.rating ?? l10n.notRatedYet,
            muted: profile.rating == null,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool muted;

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
          Icon(icon, size: 21, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              textDirection: muted ? null : TextDirection.ltr,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: muted
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
                fontSize: muted ? 15 : null,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
