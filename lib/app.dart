import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/localization/fallback_localizations.dart';
import 'core/localization/locale_controller.dart';
import 'core/push/push_destination.dart';
import 'core/push/push_service.dart';
import 'core/router/app_router.dart';
import 'core/services/preferences_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'core/widgets/exit_dialog.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/permissions/permission_gateway.dart';
import 'features/rider/data/offer_models.dart';
import 'features/rider/data/order_models.dart';
import 'features/rider/presentation/offers/incoming_offer_card.dart';
import 'features/rider/state/offer_controller.dart';
import 'features/rider/state/order_controller.dart';
import 'features/rider/state/payout_controller.dart';
import 'features/rider/state/rider_controller.dart';
import 'generated/l10n/app_localizations.dart';

class NexmileRiderApp extends StatefulWidget {
  const NexmileRiderApp({
    super.key,
    required this.preferences,
    required this.authController,
    required this.riderController,
    required this.orderController,
    required this.payoutController,
    required this.offerController,
    this.pushService = const NoopPushService(),
    this.permissionGateway,
  });

  final PreferencesService preferences;

  /// Built in `main.dart` (or by a test), because it has to exist before the
  /// API client can be told where to get its bearer token from.
  final AuthController authController;

  /// Built alongside it, sharing the same API client so the two never race to
  /// refresh the same token pair.
  final RiderController riderController;

  /// The working half of a shift: the board, the order in hand, and the
  /// position heartbeat. Built alongside the two above, sharing their API
  /// client so its timers queue behind the same refresh lock.
  final OrderController orderController;

  /// The weekly pay statements. Built alongside the rest on the same API
  /// client.
  final PayoutController payoutController;

  /// The live order offer card, if any. Shown over every screen.
  final OfferController offerController;

  /// The push transport. Defaults to the no-op one so a test — and a build
  /// with no Firebase config in it — needs to know nothing about push.
  final PushService pushService;

  /// What the first-run permission pages check and ask. Null means the real
  /// phone, through [pushService]. Off a device every check reports nothing
  /// to ask, so a test that does not pass one never meets the pages.
  final PermissionGateway? permissionGateway;

  @override
  State<NexmileRiderApp> createState() => _NexmileRiderAppState();
}

class _NexmileRiderAppState extends State<NexmileRiderApp>
    with WidgetsBindingObserver {
  /// Needed because a notification tap has no `BuildContext` of its own — it
  /// arrives from a stream, not from a widget.
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

  /// For messages about an offer that arrive from a stream, with no context.
  final GlobalKey<ScaffoldMessengerState> _messenger =
      GlobalKey<ScaffoldMessengerState>();

  StreamSubscription<Map<String, Object?>>? _taps;
  StreamSubscription<Map<String, Object?>>? _data;

  OfferController get offerController => widget.offerController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _taps = widget.pushService.onTap.listen(_follow);
    _data = widget.pushService.onData.listen(_onData);
    widget.authController.addListener(_onAuthChanged);
    // Cold start: a push may have been dropped or landed while the phone was
    // off, so the server is asked what is live rather than trusting it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncOffer());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.authController.removeListener(_onAuthChanged);
    _taps?.cancel();
    _data?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Every resume, for the same reason as the cold start — and because a
    // full-screen offer alert over the lock screen opens the app this way.
    if (state == AppLifecycleState.resumed) {
      _syncOffer();
      // Duty status can change on the server while the app is away — set
      // offline after three missed offers, say — and the toggle must show
      // what the server says, not what it said before.
      if (widget.authController.isSignedIn) unawaited(riderController.refresh());
    }
  }

  bool _confirmingExit = false;

  /// System back. Anything a screen can go back from goes back as before —
  /// the onboarding wizard steps back a page, for one. Only when there is
  /// nowhere left does it ask before closing the app.
  @override
  Future<bool> didPopRoute() async {
    // A ringing offer is answered with Accept or Reject, never by a stray
    // back press that would leave it ringing behind a closed app.
    if (offerController.offer != null) return true;

    final NavigatorState? navigator = _navigator.currentState;
    if (navigator == null) return false;
    if (await navigator.maybePop()) return true;
    final BuildContext? context = _navigator.currentContext;
    if (context == null || !context.mounted) return false;
    // Not awaited: the back press is handled the moment the question is up.
    // A second back while it is open pops the dialog, through maybePop above.
    if (!_confirmingExit) {
      _confirmingExit = true;
      unawaited(
        confirmExit(context).whenComplete(() => _confirmingExit = false),
      );
    }
    return true;
  }

  void _onAuthChanged() {
    // No card for whoever signs in next on this phone.
    if (!widget.authController.isSignedIn) offerController.reset();
  }

  Future<void> _syncOffer() async {
    if (!widget.authController.isSignedIn) return;
    await offerController.sync();
  }

  /// A dispatch message while the app is open.
  void _onData(Map<String, Object?> data) {
    if (!widget.authController.isSignedIn) return;
    final bool setOffline = offerController.handleMessage(data);
    if (setOffline) _wentOffline();
  }

  /// The server took the rider off duty for letting three offers ring out.
  /// It has already happened there; the toggle must not keep saying online.
  void _wentOffline() {
    orderController.stopTracking();
    unawaited(riderController.refresh());
    final BuildContext? context = _navigator.currentContext;
    if (context == null) return;
    _messenger.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).offerAutoOffline)),
      );
  }

  /// An accepted offer: the order is in hand, and the working screen shows it.
  void _onWon(RiderOrder order) {
    orderController.adopt(order);
    final NavigatorState? navigator = _navigator.currentState;
    if (navigator == null) return;
    navigator.popUntil((Route<Object?> route) => route.isFirst);
    navigator.pushNamed(AppRoutes.home);
  }

  /// A tap on an offer notification, or on its Accept or Decline button.
  ///
  /// The server is asked first: the notification may be for an offer that is
  /// already gone, and acting on a stale one would be worse than doing
  /// nothing.
  Future<void> _followOffer(Map<String, Object?> data) async {
    await offerController.sync();
    final OrderOffer? live = offerController.offer;
    if (live == null || live.offerId != '${data['offer_id'] ?? ''}') return;

    switch (data[kTapAction]) {
      case kOfferAcceptAction:
        final AcceptOutcome outcome = await offerController.accept();
        if (outcome case OfferWon(:final RiderOrder order)) _onWon(order);
      case kOfferDeclineAction:
        await offerController.reject();
    }
  }

  /// Opens what the notification was about.
  ///
  /// Signed out, the tap is ignored and the app opens where it always does:
  /// pushing the rider surface over the login flow would show a screen the
  /// rider has no token to fill.
  void _follow(Map<String, Object?> data) {
    if (!widget.authController.isSignedIn) return;
    switch (OfferMessage.typeOf(data)) {
      case OfferMessage.offer:
        unawaited(_followOffer(data));
        return;
      case OfferMessage.cancelled:
        return;
      case OfferMessage.autoOffline:
        _wentOffline();
        return;
    }
    final PushDestination? destination = PushDestination.fromData(data);
    if (destination == null) return;

    // An offer is only worth tapping if the order is still on the board by the
    // time the rider is looking at it, and the board's own poll can be a
    // minute behind. Fired before the navigation so the fetch and the route
    // animation overlap.
    if (destination.refreshBoard) {
      unawaited(widget.orderController.refreshBoard(silent: true));
    }

    final NavigatorState? navigator = _navigator.currentState;
    if (navigator == null) return;
    // The rider surface is a single route that resolves what to show from the
    // API, so a second copy on the stack would be the same screen twice.
    navigator.popUntil((Route<Object?> route) => route.isFirst);
    navigator.pushNamed(destination.routeName);
  }

  PreferencesService get preferences => widget.preferences;
  AuthController get authController => widget.authController;
  RiderController get riderController => widget.riderController;
  OrderController get orderController => widget.orderController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<LocaleController>(
          create: (_) => LocaleController(preferences),
        ),
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<RiderController>.value(value: riderController),
        ChangeNotifierProvider<OrderController>.value(value: orderController),
        ChangeNotifierProvider<PayoutController>.value(
          value: widget.payoutController,
        ),
        ChangeNotifierProvider<OfferController>.value(value: offerController),
        Provider<PushService>.value(value: widget.pushService),
        Provider<PreferencesService>.value(value: preferences),
        Provider<PermissionGateway>.value(
          value: widget.permissionGateway ??
              DevicePermissionGateway(push: widget.pushService),
        ),
      ],
      child: Consumer<LocaleController>(
        builder: (BuildContext context, LocaleController controller, _) {
          return MaterialApp(
            title: 'Nexmile Rider',
            debugShowCheckedModeBanner: false,

            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,

            locale: controller.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const <LocalizationsDelegate<Object>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              // Order matters: these only catch the locales the global
              // delegates above decline. See fallback_localizations.dart.
              FallbackMaterialLocalizationsDelegate(),
              FallbackCupertinoLocalizationsDelegate(),
            ],

            navigatorKey: _navigator,
            scaffoldMessengerKey: _messenger,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,

            builder: (BuildContext context, Widget? child) {
              return Directionality(
                // Driven by the selected language rather than inferred, so
                // Kashmiri and Sindhi lay out right-to-left as reliably as
                // Urdu does.
                textDirection: controller.textDirection,
                child: MediaQuery.withClampedTextScaling(
                  minScaleFactor: AppTypography.minTextScale,
                  maxScaleFactor: AppTypography.maxTextScale,
                  // Over every route, so an offer lands on top of whatever
                  // the rider was looking at, like an incoming call.
                  child: OfferOverlay(
                    onWon: _onWon,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
