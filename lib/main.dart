import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/push/device_registrar.dart';
import 'core/push/firebase_push_service.dart';
import 'core/push/push_service.dart';
import 'core/services/preferences_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_session.dart';
import 'features/auth/data/device_repository.dart';
import 'features/auth/data/token_store.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/rider/data/location_service.dart';
import 'features/rider/data/rider_repository.dart';
import 'features/rider/state/order_controller.dart';
import 'features/rider/state/rider_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only: the splash lockup and the language grid are both designed
  // for a tall viewport.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Read the stored language before the first frame so the app never flashes
  // English at a rider who has already picked something else.
  final PreferencesService preferences = await PreferencesService.create();

  // Restore the session from the platform keystore, so a returning rider goes
  // straight from the splash to the gate.
  final TokenStore tokenStore = SecureTokenStore();
  final AuthSession? session = await tokenStore.read();

  // The client and the auth controller reference each other: the client needs
  // a bearer token and a way to refresh it, the controller needs the client to
  // make calls. Build the client first, then attach the controller as its
  // token provider.
  final ApiClient apiClient = ApiClient();

  // Firebase when the project credentials are in the build, and the no-op
  // transport when they are not: a checkout with no `google-services.json`
  // still builds and runs a shift, with nothing to register and no tap to
  // route. See docs/PUSH-SETUP.md.
  final PushService pushService =
      await FirebasePushService.start() ?? const NoopPushService();
  final DeviceRegistrar deviceRegistrar = DeviceRegistrar(
    push: pushService,
    repository: ApiDeviceRepository(apiClient),
  );

  final AuthController authController = AuthController(
    repository: ApiAuthRepository(apiClient),
    tokenStore: tokenStore,
    initialSession: session,
    deviceRegistrar: deviceRegistrar,
  );
  apiClient.tokenProvider = authController;

  // The channel has to exist before the first notification lands, and a
  // mismatched id fails silently, so it is created at launch rather than at
  // sign-in.
  unawaited(pushService.ensureChannel());

  // A token can rotate while the app is closed, and a rotated token that was
  // never re-registered means an offer notification that never arrives.
  if (authController.isSignedIn) unawaited(deviceRegistrar.register());

  // Shares the same client, and therefore the same single-flight refresh lock.
  // A rider opening the app cold fires `/rider/profile` and `/rider/kyc` at
  // once; two clients would mean two refreshes, which the API treats as a
  // stolen token and answers by signing the rider out of every device.
  final ApiRiderRepository riderRepository = ApiRiderRepository(apiClient);

  final RiderController riderController = RiderController(
    repository: riderRepository,
  );

  // Shares the repository, and therefore the client, for the same reason: the
  // board poll and the position heartbeat run alongside every other rider call
  // and must queue behind the same refresh lock rather than racing it.
  final OrderController orderController = OrderController(
    repository: riderRepository,
    location: const GeolocatorLocationService(),
  );

  runApp(
    NexmileRiderApp(
      preferences: preferences,
      authController: authController,
      riderController: riderController,
      orderController: orderController,
      pushService: pushService,
    ),
  );
}
