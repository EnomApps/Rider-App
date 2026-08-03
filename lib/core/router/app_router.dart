import 'package:flutter/material.dart';

import '../../features/auth/data/login_identifier.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/language/language_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/rider/presentation/rider_gate_screen.dart';
import '../../features/splash/splash_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String language = '/language';

  // Rider auth is two screens, exactly as the customer app's is. The API
  // offers no registration or password recovery — an account is created on the
  // first successful code verification, with `intended_role: rider`.
  static const String login = '/login';
  static const String otpVerification = '/otp';

  /// The rider surface, entered through `RiderGateScreen`.
  ///
  /// Deliberately one route rather than three. What a signed-in rider is
  /// entitled to — the onboarding wizard, the waiting room, or the working
  /// home screen — is the API's decision and it can change mid-session, so it
  /// is resolved inside that screen rather than baked into a route name that
  /// would then need unwinding every time the answer changed.
  static const String home = '/home';

  static const String profile = '/profile';
}

/// Argument bundle for [AppRoutes.otpVerification].
@immutable
class OtpArgs {
  const OtpArgs({required this.identifier});

  /// The email or mobile number the code was sent to. The same value has to be
  /// sent back on verify, so it is carried rather than re-parsed.
  final LoginIdentifier identifier;
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        // Fade out of the black splash rather than sliding — a horizontal
        // push from a full-bleed black screen reads as a glitch.
        return _fadeRoute(const SplashScreen(), settings);

      case AppRoutes.language:
        final Object? args = settings.arguments;
        final bool isInitialSetup = args is bool ? args : true;
        return _fadeRoute(
          LanguageScreen(isInitialSetup: isInitialSetup),
          settings,
        );

      case AppRoutes.login:
        return _fadeRoute(const LoginScreen(), settings);

      case AppRoutes.otpVerification:
        final Object? args = settings.arguments;
        if (args is! OtpArgs) return _misroute(settings);
        return _slideRoute(OtpVerificationScreen(args: args), settings);

      case AppRoutes.home:
        return _fadeRoute(const RiderGateScreen(), settings);

      case AppRoutes.profile:
        return _slideRoute(const ProfileScreen(), settings);

      default:
        return _fadeRoute(const SplashScreen(), settings);
    }
  }

  /// A route that needs typed arguments was pushed without them. Rather than
  /// crashing on a bad cast, fall back to the start of the auth flow.
  static Route<dynamic> _misroute(RouteSettings settings) =>
      _fadeRoute(const LoginScreen(), settings);

  static PageRoute<T> _fadeRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  /// Standard forward navigation inside a flow. Uses the platform's own
  /// transition, so it slides on Android and swipes back on iOS, and it
  /// mirrors automatically in the right-to-left languages.
  static PageRoute<T> _slideRoute<T>(Widget page, RouteSettings settings) =>
      MaterialPageRoute<T>(settings: settings, builder: (_) => page);
}
