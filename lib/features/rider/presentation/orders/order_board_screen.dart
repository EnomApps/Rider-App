import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/motion/app_motion.dart';
import '../../../../core/theme/app_surface.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../data/kyc_models.dart';
import '../../data/location_service.dart';
import '../../data/order_models.dart';
import '../../data/rider_failure.dart';
import '../../data/rider_profile.dart';
import '../../state/order_controller.dart';
import '../../state/rider_controller.dart';
import 'order_details_screen.dart';
import 'widgets/order_card.dart';
import 'widgets/order_empty_state.dart';

/// The board: what a rider can take right now, nearest restaurant first.
///
/// Polls while it is on screen and stops when it is not — an idle rider
/// looking at their profile has no use for a list they cannot see, and every
/// on-duty rider in the city hits this endpoint.
///
/// An empty board is the normal state, not a failure, and `meta.can_accept`
/// says which of five situations produced it. Collapsing them into one blank
/// list is the mistake worth avoiding here: an offline rider would sit waiting
/// for orders that were never going to come.
class OrderBoardScreen extends StatefulWidget {
  const OrderBoardScreen({super.key, this.isActive = true});

  /// True while this is the tab in front.
  ///
  /// The shell keeps all four tabs alive in an `IndexedStack`, so being built
  /// is not the same as being looked at. Without this the board would poll
  /// from the moment the home screen appeared and keep polling for the whole
  /// shift, which is a request every twelve seconds for a list nobody is
  /// reading.
  final bool isActive;

  @override
  State<OrderBoardScreen> createState() => _OrderBoardScreenState();
}

class _OrderBoardScreenState extends State<OrderBoardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(OrderBoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Reading off the context is unsafe here, so the controller is captured
    // while the widget is still mounted.
    _controller?.stopBoardPolling();
    super.dispose();
  }

  OrderController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = context.read<OrderController>();
  }

  /// Polling follows the app's own lifecycle as well as the tab's. A phone in
  /// a pocket with the screen off should not be refreshing a list every twelve
  /// seconds either.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    _sync(foreground: state == AppLifecycleState.resumed);
  }

  /// One place decides whether the timer runs, from the two conditions that
  /// matter: the tab is in front, and the app is on screen.
  ///
  /// Always deferred to after the frame. `didUpdateWidget` runs *during*
  /// build, and starting the poll fetches immediately — which notifies the
  /// controller's listeners, one of which is the provider above this widget.
  /// Marking it dirty mid-build is an error, and the tab switch that triggers
  /// it is the most ordinary thing a rider does.
  void _sync({bool foreground = true}) {
    if (!mounted) return;
    final OrderController orders = context.read<OrderController>();
    final bool shouldPoll = widget.isActive && foreground;

    // Stopping is safe at any time — it touches a timer, not the tree — so
    // only the start is deferred.
    if (!shouldPoll) {
      orders.stopBoardPolling();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.isActive) return;
      orders.startBoardPolling();
    });
  }

  Future<void> _accept(RiderOrder order) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OrderController orders = context.read<OrderController>();

    final RiderFailure? failure = await orders.accept(order.id);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure == null ? l10n.orderAccepted : failure.message(l10n),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OrderController orders = context.watch<OrderController>();
    final RiderProfile? profile = context.watch<RiderController>().profile;

    final List<RiderOrder> available = orders.available;

    return RefreshIndicator(
      onRefresh: () => orders.refreshBoard(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          ...entranceGroup(<Widget>[
            Text(
              l10n.orderBoardTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                letterSpacing: -0.6,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child: BrandRule(width: 38),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.orderBoardSubtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                // A quiet sign that the list is refreshing itself, so a rider
                // watching an empty board knows the app has not stalled.
                if (orders.isLoadingBoard && available.isNotEmpty) ...<Widget>[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.8),
                  ),
                ],
              ],
            ),
          ]),
          const SizedBox(height: 18),

          // A refused location outranks whatever the board says, because it is
          // the reason the board is empty and the only one the rider can do
          // something about from here.
          if (orders.locationDenial != null) ...<Widget>[
            _LocationBanner(denial: orders.locationDenial!),
            const SizedBox(height: 16),
          ] else if (orders.boardFailure != null) ...<Widget>[
            OrderBanner(message: orders.boardFailure!.message(l10n)),
            const SizedBox(height: 16),
          ],

          if (orders.isLoadingBoard && available.isEmpty)
            // Skeletons rather than a spinner: they say what is coming as well
            // as that something is, so the first real card lands in a shape
            // the eye has already accepted.
            ...<Widget>[
              for (int i = 0; i < 2; i++) ...<Widget>[
                const _OrderSkeleton(),
                const SizedBox(height: 14),
              ],
            ]
          else if (available.isEmpty)
            EntranceFade(
              index: 3,
              child: _EmptyBoard(
                availability: orders.availability,
                profile: profile,
                hasLocationDenial: orders.locationDenial != null,
              ),
            )
          else
            for (int i = 0; i < available.length; i++) ...<Widget>[
              EntranceFade(
                // Keyed by order, so a card that was already on screen is not
                // re-animated every time the twelve-second poll returns.
                key: ValueKey<String>(available[i].id),
                index: i,
                child: OrderCard(
                  order: available[i],
                  isBusy: orders.isActing,
                  onAccept: () => _accept(available[i]),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => OrderDetailsScreen(order: available[i]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}

/// The board's five empty states, chosen from `meta.can_accept`.
///
/// The duty status is consulted only as a fallback: the server's own answer is
/// the one that counts, and this build may meet a reason it does not model.
class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({
    required this.availability,
    required this.profile,
    required this.hasLocationDenial,
  });

  final BoardAvailability availability;
  final RiderProfile? profile;
  final bool hasLocationDenial;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    BoardAvailability resolved = availability;
    if (resolved == BoardAvailability.unknown) {
      // No answer from the server this build understands. The device already
      // knows two of the five, so use what it has rather than showing the
      // generic "no orders" to a rider who is plainly offline.
      if (hasLocationDenial) {
        resolved = BoardAvailability.noLocation;
      } else if (profile != null &&
          profile!.dutyStatus != DutyStatus.available) {
        resolved = BoardAvailability.offline;
      }
    }

    switch (resolved) {
      case BoardAvailability.offline:
        return OrderEmptyState(
          icon: Icons.power_settings_new_rounded,
          title: l10n.boardOfflineTitle,
          body: l10n.boardOfflineBody,
        );
      case BoardAvailability.onOrder:
        return OrderEmptyState(
          icon: Icons.delivery_dining_outlined,
          title: l10n.boardBusyTitle,
          body: l10n.boardBusyBody,
        );
      case BoardAvailability.noLocation:
        return OrderEmptyState(
          icon: Icons.location_off_outlined,
          title: l10n.boardNoLocationTitle,
          body: l10n.boardNoLocationBody,
        );
      case BoardAvailability.notVerified:
        return OrderEmptyState(
          icon: Icons.verified_user_outlined,
          title: l10n.boardNotVerifiedTitle,
          body: l10n.awaitingVerificationMessage,
        );
      case BoardAvailability.available:
      case BoardAvailability.unknown:
        return OrderEmptyState(
          icon: Icons.inbox_outlined,
          title: l10n.boardEmptyTitle,
          body: l10n.boardEmptyBody,
        );
    }
  }
}

/// The device refused a position. Says why, and offers the one thing that
/// helps — which differs by refusal: a prompt can be shown again, a permanent
/// denial can only be undone in the system settings.
class _LocationBanner extends StatelessWidget {
  const _LocationBanner({required this.denial});

  final LocationDenial denial;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OrderController orders = context.read<OrderController>();

    final bool askable = denial == LocationDenial.permissionDenied ||
        denial == LocationDenial.unavailable;

    return OrderBanner(
      icon: Icons.location_off_outlined,
      message: l10n.locationPermissionBody,
      action: TextButton(
        onPressed: () async {
          if (askable) {
            final RiderFailure? failure = await orders.primeLocation();
            if (failure == null) orders.startTracking();
            return;
          }
          await openLocationSettings(denial);
        },
        child: Text(
          askable ? l10n.enableLocationButton : l10n.locationSettingsButton,
        ),
      ),
    );
  }
}

/// The shape of an order card, while the real one is on its way.
///
/// Traced from [OrderCard] rather than being a generic grey block: the point
/// is that the rider's eye is already in the right place when the content
/// arrives.
class _OrderSkeleton extends StatelessWidget {
  const _OrderSkeleton();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: AppSurface.radiusLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              Shimmer(width: 110, height: 15),
              Spacer(),
              Shimmer(width: 78, height: 20, radius: 999),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Shimmer(width: 11, height: 74, radius: 6),
              const SizedBox(width: 19),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[
                    Shimmer(width: 96, height: 11),
                    SizedBox(height: 7),
                    Shimmer(height: 13),
                    SizedBox(height: 18),
                    Shimmer(width: 82, height: 11),
                    SizedBox(height: 7),
                    Shimmer(height: 13),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: const <Widget>[
              Expanded(child: Shimmer(width: 62, height: 26)),
              Expanded(child: Shimmer(width: 62, height: 26)),
              Expanded(child: Shimmer(width: 48, height: 26)),
            ],
          ),
        ],
      ),
    );
  }
}
