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
import 'features/auth/state/auth_controller.dart';
import 'features/rider/state/order_controller.dart';
import 'features/rider/state/rider_controller.dart';
import 'generated/l10n/app_localizations.dart';

class NexmileRiderApp extends StatefulWidget {
  const NexmileRiderApp({
    super.key,
    required this.preferences,
    required this.authController,
    required this.riderController,
    required this.orderController,
    this.pushService = const NoopPushService(),
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

  /// The push transport. Defaults to the no-op one so a test — and a build
  /// with no Firebase config in it — needs to know nothing about push.
  final PushService pushService;

  @override
  State<NexmileRiderApp> createState() => _NexmileRiderAppState();
}

class _NexmileRiderAppState extends State<NexmileRiderApp> {
  /// Needed because a notification tap has no `BuildContext` of its own — it
  /// arrives from a stream, not from a widget.
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

  StreamSubscription<Map<String, Object?>>? _taps;

  @override
  void initState() {
    super.initState();
    _taps = widget.pushService.onTap.listen(_follow);
  }

  @override
  void dispose() {
    _taps?.cancel();
    super.dispose();
  }

  /// Opens what the notification was about.
  ///
  /// Signed out, the tap is ignored and the app opens where it always does:
  /// pushing the rider surface over the login flow would show a screen the
  /// rider has no token to fill.
  void _follow(Map<String, Object?> data) {
    if (!widget.authController.isSignedIn) return;
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
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
