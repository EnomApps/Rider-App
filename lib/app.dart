import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/localization/fallback_localizations.dart';
import 'core/localization/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/services/preferences_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/rider/state/order_controller.dart';
import 'features/rider/state/rider_controller.dart';
import 'generated/l10n/app_localizations.dart';

class NexmileRiderApp extends StatelessWidget {
  const NexmileRiderApp({
    super.key,
    required this.preferences,
    required this.authController,
    required this.riderController,
    required this.orderController,
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
