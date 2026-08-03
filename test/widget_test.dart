import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexmile_rider/app.dart';
import 'package:nexmile_rider/core/constants/app_assets.dart';
import 'package:nexmile_rider/core/localization/app_language.dart';
import 'package:nexmile_rider/core/widgets/info_tile.dart';
import 'package:nexmile_rider/core/network/api_client.dart';
import 'package:nexmile_rider/core/network/api_exception.dart';
import 'package:nexmile_rider/core/network/api_log.dart';
import 'package:nexmile_rider/core/router/app_router.dart';
import 'package:nexmile_rider/core/services/preferences_service.dart';
import 'package:nexmile_rider/features/auth/data/auth_repository.dart';
import 'package:nexmile_rider/features/auth/data/auth_session.dart';
import 'package:nexmile_rider/features/auth/data/auth_user.dart';
import 'package:nexmile_rider/features/auth/data/login_identifier.dart';
import 'package:nexmile_rider/features/auth/data/token_store.dart';
import 'package:nexmile_rider/features/auth/presentation/login_screen.dart';
import 'package:nexmile_rider/features/auth/presentation/otp_verification_screen.dart';
import 'package:nexmile_rider/features/auth/state/auth_controller.dart';
import 'package:nexmile_rider/features/rider/data/document_catalogue.dart';
import 'package:nexmile_rider/features/rider/data/kyc_models.dart';
import 'package:nexmile_rider/features/rider/data/kyc_validators.dart';
import 'package:nexmile_rider/features/rider/data/picked_document.dart';
import 'package:nexmile_rider/features/rider/data/rider_failure.dart';
import 'package:nexmile_rider/features/rider/data/rider_profile.dart';
import 'package:nexmile_rider/features/rider/data/rider_repository.dart';
import 'package:nexmile_rider/features/rider/presentation/home/rider_home_screen.dart';
import 'package:nexmile_rider/features/rider/presentation/onboarding/onboarding_screen.dart';
import 'package:nexmile_rider/features/rider/presentation/review/kyc_decision_screen.dart';
import 'package:nexmile_rider/features/rider/state/rider_controller.dart';
import 'package:nexmile_rider/features/language/language_screen.dart';
import 'package:nexmile_rider/features/profile/profile_screen.dart';
import 'package:nexmile_rider/features/splash/splash_screen.dart';
import 'package:nexmile_rider/generated/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// A rider, and therefore `pending` rather than `active`.
///
/// This is the fixture-level statement of the difference from the customer
/// app: verifying a code does not make a rider usable, and every test that
/// signs in has to reckon with what comes next.
const AuthUser _testUser = AuthUser(
  id: 42,
  name: 'Priya Kumar',
  email: 'priya@example.com',
  phone: '9876543210',
  role: UserRole.rider,
  status: UserStatus.pending,
);

/// The six documents a rider is asked for, as the API names them.
const List<String> _riderDocuments = <String>[
  'aadhaar_front',
  'aadhaar_back',
  'driving_licence',
  'rc',
  'insurance',
  'profile_photo',
];

AuthSession _testSession() => const AuthSession(
      user: _testUser,
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresIn: 3600,
    );

/// Scriptable stand-in for the live API.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.validCode = '123456'});

  final String validCode;

  ApiException? requestError;
  ApiException? verifyError;
  ApiException? profileError;
  int resendAfter = 60;
  String? debugCode;

  /// What `GET /v1/profile` returns; defaults to the signed-in fixture.
  AuthUser profileUser = _testUser;

  int requestCount = 0;
  int verifyCount = 0;
  int signOutCount = 0;
  int profileCount = 0;
  LoginIdentifier? lastIdentifier;
  String? lastCode;

  @override
  Future<OtpChallenge> requestCode(LoginIdentifier identifier) async {
    requestCount++;
    lastIdentifier = identifier;
    final ApiException? error = requestError;
    if (error != null) throw error;
    return OtpChallenge(
      identifier: identifier.value,
      channel: identifier.isEmail ? 'email' : 'sms',
      expiresIn: 300,
      resendAfter: resendAfter,
      debugCode: debugCode,
    );
  }

  @override
  Future<AuthSession> verifyCode({
    required LoginIdentifier identifier,
    required String code,
    String? deviceName,
  }) async {
    verifyCount++;
    lastCode = code;
    final ApiException? error = verifyError;
    if (error != null) throw error;
    if (code != validCode) {
      throw const ApiException(kind: ApiErrorKind.validation, statusCode: 422);
    }
    return _testSession();
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async => _testSession();

  @override
  Future<AuthUser> me() async => _testUser;

  @override
  Future<AuthUser> profile() async {
    profileCount++;
    final ApiException? error = profileError;
    if (error != null) throw error;
    return profileUser;
  }

  @override
  Future<void> signOut() async => signOutCount++;
}

/// Scriptable stand-in for `/v1/rider`.
///
/// Models the API's actual behaviour rather than just returning fixtures:
/// saving details recomputes `can_submit`, submitting flips the status to
/// `submitted`, and `can_accept_orders` follows verification. That is what
/// makes it worth having — the gate's whole job is to react to those
/// transitions, and a repository that only ever returned one shape could not
/// exercise it.
class FakeRiderRepository implements RiderRepository {
  FakeRiderRepository({
    this.kycStatus = KycStatus.pending,
    this.canAcceptOrders = false,
    this.fullName = '',
    this.vehicleType = VehicleType.unknown,
    List<String>? uploaded,
    this.rejectionReason,
  }) : _uploaded = <String>{...?uploaded};

  KycStatus kycStatus;
  bool canAcceptOrders;
  String fullName;
  VehicleType vehicleType;
  String? vehicleNumber;

  // The three KYC fields `RiderResource` actually echoes back. Aadhaar and the
  // bank details are hidden server-side and never returned, so the fake does
  // not return them either — the wizard's resume logic has to work from
  // exactly this much and no more.
  String? pan;
  String? drivingLicenceNo;
  DateTime? insuranceExpiry;

  String? rejectionReason;
  DutyStatus dutyStatus = DutyStatus.offline;
  bool documentsExpired = false;

  final Set<String> _uploaded;

  ApiException? profileError;
  ApiException? detailsError;
  ApiException? dutyError;
  ApiException? uploadError;

  int profileCount = 0;
  int detailsCount = 0;
  int submitCount = 0;
  int uploadCount = 0;
  KycDetails? lastDetails;
  DutyStatus? lastDuty;

  /// All eleven reference fields, accumulated across the wizard's steps —
  /// exactly as the real API accumulates them.
  final Map<String, Object?> savedDetails = <String, Object?>{};

  @override
  Future<RiderProfile> profile() async {
    profileCount++;
    final ApiException? error = profileError;
    if (error != null) throw error;
    return _profile();
  }

  RiderProfile _profile() => RiderProfile(
        id: 7,
        fullName: fullName,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        kyc: RiderKycSummary(
          status: kycStatus,
          documentsExpired: documentsExpired,
          rejectionReason: rejectionReason,
          pan: pan,
          drivingLicenceNo: drivingLicenceNo,
          insuranceExpiry: insuranceExpiry,
        ),
        dutyStatus: dutyStatus,
        canAcceptOrders: canAcceptOrders,
        completedDeliveries: 12,
        rating: '4.8',
      );

  @override
  Future<RiderProfile> updateProfile({
    String? fullName,
    DateTime? dateOfBirth,
    VehicleType? vehicleType,
    String? vehicleNumber,
  }) async {
    final ApiException? error = detailsError;
    if (error != null) throw error;
    if (fullName != null) this.fullName = fullName;
    if (vehicleType != null) this.vehicleType = vehicleType;
    if (vehicleNumber != null) this.vehicleNumber = vehicleNumber;
    return _profile();
  }

  @override
  Future<RiderProfile> setDutyStatus(DutyStatus status) async {
    lastDuty = status;
    final ApiException? error = dutyError;
    if (error != null) throw error;
    dutyStatus = status;
    return _profile();
  }

  @override
  Future<KycOverview> kyc() async => KycOverview(
        status: kycStatus,
        rejectionReason: rejectionReason,
        allowedDocuments: _riderDocuments,
        missingDocuments: <String>[
          for (final String type in _riderDocuments)
            if (!_uploaded.contains(type)) type,
        ],
        // Mirrors the server rule: everything uploaded and every reference
        // number on file.
        canSubmit: _uploaded.length == _riderDocuments.length &&
            savedDetails.length >= 11,
        documents: <KycDocument>[
          for (final String type in _uploaded)
            KycDocument(
              id: _riderDocuments.indexOf(type) + 1,
              type: type,
              label: type,
              status: DocumentStatus.pending,
              originalName: '$type.jpg',
              sizeBytes: 1024,
            ),
        ],
      );

  @override
  Future<void> updateKycDetails(KycDetails details) async {
    detailsCount++;
    lastDetails = details;
    final ApiException? error = detailsError;
    if (error != null) throw error;
    savedDetails.addAll(details.toJson());
    if (details.pan != null) pan = details.pan;
    if (details.drivingLicenceNo != null) {
      drivingLicenceNo = details.drivingLicenceNo;
    }
    if (details.insuranceExpiry != null) {
      insuranceExpiry = details.insuranceExpiry;
    }
  }

  @override
  Future<KycDocument> uploadDocument({
    required String type,
    required PickedDocument file,
  }) async {
    uploadCount++;
    final ApiException? error = uploadError;
    if (error != null) throw error;
    _uploaded.add(type);
    return KycDocument(
      id: _riderDocuments.indexOf(type) + 1,
      type: type,
      label: type,
      status: DocumentStatus.pending,
      originalName: file.filename,
      sizeBytes: file.sizeBytes,
    );
  }

  @override
  Future<void> deleteDocument(int documentId) async {
    _uploaded.removeWhere(
      (String type) => _riderDocuments.indexOf(type) + 1 == documentId,
    );
  }

  @override
  Future<KycOverview> submitKyc() async {
    submitCount++;
    kycStatus = KycStatus.submitted;
    return kyc();
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const Map<String, Object> _freshInstall = <String, Object>{};

const Map<String, Object> _languageChosen = <String, Object>{
  'nexmile.language_code': 'en',
  'nexmile.language_chosen': true,
};

Map<String, Object> _languageChosenAs(String code) => <String, Object>{
      'nexmile.language_code': code,
      'nexmile.language_chosen': true,
    };

Future<PreferencesService> _prefs(Map<String, Object> seed) async {
  SharedPreferences.setMockInitialValues(seed);
  return PreferencesService.create();
}

late AuthController _controller;
late RiderController _rider;

Future<void> _pumpApp(
  WidgetTester tester, {
  Map<String, Object> seed = _freshInstall,
  FakeAuthRepository? repository,
  FakeRiderRepository? riderRepository,
  AuthSession? session,
}) async {
  final PreferencesService preferences = await _prefs(seed);
  _controller = AuthController(
    repository: repository ?? FakeAuthRepository(),
    tokenStore: InMemoryTokenStore(session),
    initialSession: session,
  );
  _rider = RiderController(
    // Defaults to an approved rider, so the tests inherited from the customer
    // app still land somewhere they can assert against. Tests about the gate
    // pass their own.
    repository: riderRepository ?? _approvedRider(),
  );
  await tester.pumpWidget(
    NexmileRiderApp(
      preferences: preferences,
      authController: _controller,
      riderController: _rider,
    ),
  );
}

/// A rider who has been through onboarding and may work.
FakeRiderRepository _approvedRider() => FakeRiderRepository(
      kycStatus: KycStatus.verified,
      canAcceptOrders: true,
      fullName: 'Priya Kumar',
      vehicleType: VehicleType.motorcycle,
      uploaded: _riderDocuments,
    );

Future<void> _settleSplash(WidgetTester tester) async {
  await tester.pump(SplashScreen.totalDuration);
  await tester.pumpAndSettle();
}

NavigatorState _nav(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator).last);

/// The default 800x600 test surface is shorter than a real phone. Auth screens
/// are short enough to fit, but the dashboard and OTP screen benefit from a
/// realistic viewport.
void _useTallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  // -------------------------------------------------------------------------
  group('language catalogue', () {
    test('ships English plus all 22 Eighth Schedule languages', () {
      expect(AppLanguages.all.length, 23);
    });

    test('every language has an ARB-backed locale', () {
      final Set<String> generated = AppLocalizations.supportedLocales
          .map((Locale l) => l.languageCode)
          .toSet();
      for (final AppLanguage language in AppLanguages.all) {
        expect(
          generated.contains(language.code),
          isTrue,
          reason: 'missing lib/l10n/app_${language.code}.arb',
        );
      }
    });

    test('English is the one and only default', () {
      expect(
        AppLanguages.all.where((AppLanguage l) => l.isDefault).toList(),
        <AppLanguage>[AppLanguages.english],
      );
      expect(AppLanguages.fallback.code, 'en');
    });

    test('unknown or absent codes fall back to English', () {
      expect(AppLanguages.byCode(null).code, 'en');
      expect(AppLanguages.byCode('zz').code, 'en');
      expect(AppLanguages.fromLocale(const Locale('ta', 'LK')).code, 'ta');
    });

    test('only the Perso-Arabic scripts are right-to-left', () {
      final Set<String> rtl = AppLanguages.all
          .where((AppLanguage l) => l.isRtl)
          .map((AppLanguage l) => l.code)
          .toSet();
      expect(rtl, <String>{'ur', 'ks', 'sd'});
    });
  });

  // -------------------------------------------------------------------------
  group('translations', () {
    testWidgets('every locale resolves its own copy',
        (WidgetTester tester) async {
      for (final AppLanguage language in AppLanguages.all) {
        final AppLocalizations l10n =
            await AppLocalizations.delegate.load(language.locale);
        expect(l10n.appName, 'Nexmile Rider');
        for (final String value in <String>[
          l10n.continueLabel,
          l10n.chooseLanguageTitle,
          l10n.riderHomeTitle,
          l10n.loginTitle,
          l10n.emailOrPhoneLabel,
          l10n.sendCode,
          l10n.otpTitle,
          l10n.verifyCode,
          l10n.incorrectCode,
          l10n.accountSuspended,
          l10n.tooManyAttempts,
          l10n.sessionExpired,
          l10n.networkError,
          l10n.signOut,
          l10n.profileTitle,
          l10n.viewProfile,
          l10n.nameLabel,
          l10n.emailLabel,
          l10n.mobileLabel,
          l10n.accountStatusLabel,
          l10n.statusActive,
          l10n.verifiedLabel,
          l10n.notProvided,
          l10n.retry,
        ]) {
          expect(value.trim(), isNotEmpty, reason: language.englishName);
        }
      }
    });

    testWidgets('no locale silently reuses an English string',
        (WidgetTester tester) async {
      final AppLocalizations en =
          await AppLocalizations.delegate.load(const Locale('en'));
      for (final AppLanguage language in AppLanguages.all) {
        if (language.code == 'en') continue;
        final AppLocalizations l10n =
            await AppLocalizations.delegate.load(language.locale);
        expect(l10n.chooseLanguageTitle, isNot(en.chooseLanguageTitle),
            reason: '${language.englishName}: language screen');
        expect(l10n.loginTitle, isNot(en.loginTitle),
            reason: '${language.englishName}: login screen');
        expect(l10n.incorrectCode, isNot(en.incorrectCode),
            reason: '${language.englishName}: OTP errors');
        expect(l10n.networkError, isNot(en.networkError),
            reason: '${language.englishName}: network errors');
        expect(l10n.accountStatusLabel, isNot(en.accountStatusLabel),
            reason: '${language.englishName}: profile screen');
      }
    });

    testWidgets('placeholders survive translation in every locale',
        (WidgetTester tester) async {
      for (final AppLanguage language in AppLanguages.all) {
        final AppLocalizations l10n =
            await AppLocalizations.delegate.load(language.locale);
        expect(l10n.otpSubtitle('9876543210'), contains('9876543210'));
        expect(l10n.resendCodeIn(60), contains('60'));
        expect(l10n.greetingNamed('Priya'), contains('Priya'));
        expect(l10n.languagesAvailable(23), contains('23'));
      }
    });
  });

  // -------------------------------------------------------------------------
  group('LoginIdentifier', () {
    test('accepts a plain email and lowercases it', () {
      final LoginIdentifier? id = LoginIdentifier.tryParse('  Priya@Example.COM ');
      expect(id?.isEmail, isTrue);
      expect(id?.value, 'priya@example.com');
      expect(id?.toJson(), <String, dynamic>{'email': 'priya@example.com'});
    });

    test('accepts a bare 10-digit mobile number', () {
      final LoginIdentifier? id = LoginIdentifier.tryParse('9876543210');
      expect(id?.isPhone, isTrue);
      expect(id?.toJson(), <String, dynamic>{'phone': '9876543210'});
    });

    test('normalises the ways an Indian number is commonly typed', () {
      for (final String input in <String>[
        '+91 98765 43210',
        '+919876543210',
        '919876543210',
        '09876543210',
        '98765-43210',
        '(98765) 43210',
      ]) {
        expect(
          LoginIdentifier.tryParse(input)?.value,
          '9876543210',
          reason: input,
        );
      }
    });

    test('rejects anything that is neither', () {
      for (final String input in <String>[
        '',
        '   ',
        'not-an-email',
        'a@b',
        '1234567890', // does not start 6-9
        '5876543210',
        '98765',
        '98765432101',
        'priya@@example.com',
      ]) {
        expect(LoginIdentifier.tryParse(input), isNull, reason: input);
      }
    });

    test('never sends both email and phone', () {
      for (final String input in <String>['a@b.com', '9876543210']) {
        expect(LoginIdentifier.tryParse(input)!.toJson().length, 1);
      }
    });
  });

  // -------------------------------------------------------------------------
  group('ApiClient', () {
    late List<http.Request> seen;

    setUp(() => seen = <http.Request>[]);

    ApiClient clientReturning(
      Future<http.Response> Function(http.Request request) handler, {
      TokenProvider? tokens,
    }) {
      return ApiClient(
        baseUrl: 'https://api.test/api',
        tokenProvider: tokens,
        httpClient: MockClient((http.Request request) {
          seen.add(request);
          return handler(request);
        }),
      );
    }

    test('sends Accept: application/json on every request', () async {
      final ApiClient client = clientReturning(
        (_) async => http.Response('{"data":{}}', 200),
      );
      await client.get('/v1/auth/me', authenticated: false);
      expect(seen.single.headers['Accept'], 'application/json');
    });

    test('attaches the bearer token when authenticated', () async {
      final _StubTokens tokens = _StubTokens('tok');
      final ApiClient client = clientReturning(
        (_) async => http.Response('{"data":{}}', 200),
        tokens: tokens,
      );
      await client.get('/v1/auth/me');
      expect(seen.single.headers['Authorization'], 'Bearer tok');
    });

    test('maps status codes onto error kinds', () async {
      Future<ApiErrorKind> kindFor(int status, [String body = '{}']) async {
        final ApiClient client = clientReturning(
          (_) async => http.Response(body, status),
        );
        try {
          await client.get('/x', authenticated: false);
          fail('expected a throw for $status');
        } on ApiException catch (e) {
          return e.kind;
        }
      }

      expect(await kindFor(401), ApiErrorKind.unauthenticated);
      expect(await kindFor(403), ApiErrorKind.forbidden);
      expect(await kindFor(422), ApiErrorKind.validation);
      expect(await kindFor(429), ApiErrorKind.tooManyRequests);
      expect(await kindFor(500), ApiErrorKind.server);
    });

    test('exposes 422 field errors', () async {
      final ApiClient client = clientReturning(
        (_) async => http.Response(
          jsonEncode(<String, dynamic>{
            'message': 'Validation failed',
            'errors': <String, dynamic>{
              'code': <String>['The code is invalid.'],
            },
          }),
          422,
        ),
      );
      try {
        await client.post('/x', authenticated: false);
        fail('expected a throw');
      } on ApiException catch (e) {
        expect(e.isValidation, isTrue);
        expect(e.errorFor('code'), 'The code is invalid.');
      }
    });

    test('an HTML body does not crash the decoder', () async {
      final ApiClient client = clientReturning(
        (_) async => http.Response('<html>redirect</html>', 302),
      );
      await expectLater(
        client.get('/x', authenticated: false),
        throwsA(isA<ApiException>()),
      );
    });

    test('a 401 triggers one refresh and one retry', () async {
      final _StubTokens tokens = _StubTokens('stale', refreshResult: true);
      int calls = 0;
      final ApiClient client = clientReturning(
        (_) async {
          calls++;
          return calls == 1
              ? http.Response('{"message":"Unauthenticated."}', 401)
              : http.Response('{"data":{"ok":true}}', 200);
        },
        tokens: tokens,
      );

      final Map<String, dynamic> result = await client.get('/v1/auth/me');

      expect(result['data'], <String, dynamic>{'ok': true});
      expect(tokens.refreshCalls, 1);
      expect(calls, 2, reason: 'exactly one retry');
    });

    test('a failed refresh drops the session and does not loop', () async {
      final _StubTokens tokens = _StubTokens('stale', refreshResult: false);
      int calls = 0;
      final ApiClient client = clientReturning(
        (_) async {
          calls++;
          return http.Response('{"message":"Unauthenticated."}', 401);
        },
        tokens: tokens,
      );

      await expectLater(
        client.get('/v1/auth/me'),
        throwsA(isA<ApiException>()),
      );
      expect(tokens.refreshCalls, 1);
      expect(tokens.sessionLostCalls, 1);
      expect(calls, 1, reason: 'no retry when the refresh failed');
    });

    test('concurrent 401s share a single refresh', () async {
      // The API treats two parallel refreshes as a stolen token and signs the
      // customer out everywhere, so this is the behaviour that matters most.
      final _StubTokens tokens = _StubTokens('stale', refreshResult: true);
      final Map<String, int> callsPerPath = <String, int>{};
      final ApiClient client = clientReturning(
        (http.Request request) async {
          final String path = request.url.path;
          callsPerPath[path] = (callsPerPath[path] ?? 0) + 1;
          return callsPerPath[path] == 1
              ? http.Response('{"message":"Unauthenticated."}', 401)
              : http.Response('{"data":{}}', 200);
        },
        tokens: tokens,
      );

      await Future.wait<Map<String, dynamic>>(<Future<Map<String, dynamic>>>[
        client.get('/a'),
        client.get('/b'),
        client.get('/c'),
      ]);

      expect(tokens.refreshCalls, 1);
    });
  });

  // -------------------------------------------------------------------------
  group('splash hand-off', () {
    testWidgets('fresh install lands on the language screen',
        (WidgetTester tester) async {
      await _pumpApp(tester);
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.image(const AssetImage(AppAssets.symbol)), findsOneWidget);
      expect(find.image(const AssetImage(AppAssets.wordmark)), findsOneWidget);

      await _settleSplash(tester);
      expect(find.byType(LanguageScreen), findsOneWidget);
    });

    testWidgets('language chosen, no session -> login',
        (WidgetTester tester) async {
      await _pumpApp(tester, seed: _languageChosen);
      await _settleSplash(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('restored session -> dashboard', (WidgetTester tester) async {
      await _pumpApp(
        tester,
        seed: _languageChosen,
        session: _testSession(),
      );
      await _settleSplash(tester);

      expect(find.byType(RiderHomeScreen), findsOneWidget);
      expect(find.text('Hello, Priya'), findsOneWidget);
    });

    testWidgets('splash paints every frame without error',
        (WidgetTester tester) async {
      await _pumpApp(tester);
      for (int i = 0; i < 180; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull, reason: 'frame $i');
      }
      await tester.pumpAndSettle();
      expect(find.byType(LanguageScreen), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  group('language screen', () {
    testWidgets('continues into login', (WidgetTester tester) async {
      await _pumpApp(tester);
      await _settleSplash(tester);

      expect(find.text('Choose your language'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('picking Tamil carries through to login',
        (WidgetTester tester) async {
      await _pumpApp(tester);
      await _settleSplash(tester);

      await tester.tap(find.text('தமிழ்'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('தொடரவும்'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Nexmile-இல் உள்நுழையவும்'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  group('sign in', () {
    testWidgets('an email requests a code and opens the OTP screen',
        (WidgetTester tester) async {
      final FakeAuthRepository repo = FakeAuthRepository();
      await _pumpApp(tester, seed: _languageChosen, repository: repo);
      await _settleSplash(tester);

      await tester.enterText(find.byType(TextFormField), 'priya@example.com');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      expect(repo.requestCount, 1);
      expect(repo.lastIdentifier?.isEmail, isTrue);
      expect(repo.lastIdentifier?.value, 'priya@example.com');
    });

    testWidgets('a mobile number is sent as phone, not email',
        (WidgetTester tester) async {
      final FakeAuthRepository repo = FakeAuthRepository();
      await _pumpApp(tester, seed: _languageChosen, repository: repo);
      await _settleSplash(tester);

      await tester.enterText(find.byType(TextFormField), '+91 98765 43210');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      expect(repo.lastIdentifier?.isPhone, isTrue);
      expect(repo.lastIdentifier?.toJson(), <String, dynamic>{
        'phone': '9876543210',
      });
    });

    testWidgets('rubbish input is rejected before any request',
        (WidgetTester tester) async {
      final FakeAuthRepository repo = FakeAuthRepository();
      await _pumpApp(tester, seed: _languageChosen, repository: repo);
      await _settleSplash(tester);

      await tester.enterText(find.byType(TextFormField), 'not-valid');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter a valid email address or 10-digit mobile number'),
        findsWidgets,
      );
      expect(repo.requestCount, 0);
      expect(find.byType(OtpVerificationScreen), findsNothing);
    });

    testWidgets('a network failure is reported in the chosen language',
        (WidgetTester tester) async {
      final FakeAuthRepository repo = FakeAuthRepository()
        ..requestError = const ApiException(kind: ApiErrorKind.network);
      await _pumpApp(
        tester,
        seed: _languageChosenAs('ta'),
        repository: repo,
      );
      await _settleSplash(tester);

      await tester.enterText(find.byType(TextFormField), '9876543210');
      await tester.tap(find.text('குறியீட்டை அனுப்பு'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'இணைய இணைப்பு இல்லை. உங்கள் இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
        ),
        findsOneWidget,
      );
      expect(find.byType(OtpVerificationScreen), findsNothing);
    });

    testWidgets('a 429 shows the rate-limit message',
        (WidgetTester tester) async {
      final FakeAuthRepository repo = FakeAuthRepository()
        ..requestError =
            const ApiException(kind: ApiErrorKind.tooManyRequests);
      await _pumpApp(tester, seed: _languageChosen, repository: repo);
      await _settleSplash(tester);

      await tester.enterText(find.byType(TextFormField), '9876543210');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      expect(
        find.text('Too many attempts. Please wait a while and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('a suspended account is reported', (WidgetTester tester) async {
      final FakeAuthRepository repo = FakeAuthRepository()
        ..requestError = const ApiException(kind: ApiErrorKind.forbidden);
      await _pumpApp(tester, seed: _languageChosen, repository: repo);
      await _settleSplash(tester);

      await tester.enterText(find.byType(TextFormField), '9876543210');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      expect(
        find.text('This account has been suspended. Please contact support.'),
        findsOneWidget,
      );
    });
  });

  // -------------------------------------------------------------------------
  group('code verification', () {
    Future<FakeAuthRepository> reachOtp(
      WidgetTester tester, {
      FakeAuthRepository? repository,
      String identifier = '9876543210',
      Map<String, Object> seed = _languageChosen,
    }) async {
      final FakeAuthRepository repo = repository ?? FakeAuthRepository();
      await _pumpApp(tester, seed: seed, repository: repo);
      await _settleSplash(tester);
      await tester.enterText(find.byType(TextFormField), identifier);
      await tester.tap(find.byType(InkWell).last);
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('the correct code signs in and reaches the dashboard',
        (WidgetTester tester) async {
      _useTallPhone(tester);
      final FakeAuthRepository repo = await reachOtp(tester);
      expect(find.byType(OtpVerificationScreen), findsOneWidget);

      // Entering the final digit auto-submits.
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pumpAndSettle();

      expect(find.byType(RiderHomeScreen), findsOneWidget);
      expect(find.text('Hello, Priya'), findsOneWidget);
      expect(repo.verifyCount, 1);
      expect(repo.lastCode, '123456');
      expect(_controller.isSignedIn, isTrue);
    });

    testWidgets('a wrong code is rejected and the boxes are cleared',
        (WidgetTester tester) async {
      _useTallPhone(tester);
      await reachOtp(tester);

      await tester.enterText(find.byType(TextField).first, '000000');
      await tester.pumpAndSettle();

      expect(
        find.text(
          'That code is not correct or has expired. Request a new one.',
        ),
        findsOneWidget,
      );
      expect(find.byType(RiderHomeScreen), findsNothing);
      expect(_controller.isSignedIn, isFalse);
    });

    testWidgets('an incomplete code is caught before any request',
        (WidgetTester tester) async {
      _useTallPhone(tester);
      final FakeAuthRepository repo = await reachOtp(tester);

      await tester.enterText(find.byType(TextField).first, '12');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(find.text('Enter all 6 digits'), findsOneWidget);
      expect(repo.verifyCount, 0);
    });

    testWidgets('resend is locked behind the server-supplied cooldown',
        (WidgetTester tester) async {
      _useTallPhone(tester);
      final FakeAuthRepository repo = FakeAuthRepository()..resendAfter = 45;
      await reachOtp(tester, repository: repo);

      expect(find.text('Resend code'), findsNothing);
      expect(find.text('Resend code in 45s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 46));
      await tester.pumpAndSettle();
      expect(find.text('Resend code'), findsOneWidget);

      await tester.tap(find.text('Resend code'));
      await tester.pumpAndSettle();

      expect(find.text('A new code has been sent'), findsOneWidget);
      expect(repo.requestCount, 2);
    });

    testWidgets('the subtitle names the identifier the code went to',
        (WidgetTester tester) async {
      _useTallPhone(tester);
      await reachOtp(tester, identifier: 'priya@example.com');
      expect(find.textContaining('priya@example.com'), findsWidgets);
    });

    testWidgets('the OTP route without arguments falls back to login',
        (WidgetTester tester) async {
      await _pumpApp(tester, seed: _languageChosen);
      await _settleSplash(tester);

      _nav(tester).pushNamed(AppRoutes.otpVerification);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  group('profile', () {
    /// Signs in from a restored session and opens the profile screen.
    Future<FakeAuthRepository> openProfile(
      WidgetTester tester, {
      FakeAuthRepository? repository,
      Map<String, Object> seed = _languageChosen,
    }) async {
      _useTallPhone(tester);
      final FakeAuthRepository repo = repository ?? FakeAuthRepository();
      await _pumpApp(
        tester,
        seed: seed,
        repository: repo,
        session: _testSession(),
      );
      await _settleSplash(tester);
      await tester.tap(find.byIcon(Icons.person_outline_rounded).first);
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('opens from the dashboard and fetches GET /v1/profile',
        (WidgetTester tester) async {
      final FakeAuthRepository repo = await openProfile(tester);

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(repo.profileCount, 1);
      expect(find.text('Profile'), findsWidgets);
    });

    testWidgets('renders the fields the API returned',
        (WidgetTester tester) async {
      final FakeAuthRepository repo = FakeAuthRepository()
        ..profileUser = const AuthUser(
          id: 42,
          name: 'Priya Kumar',
          email: 'priya@example.com',
          phone: '9876543210',
          role: UserRole.customer,
          status: UserStatus.active,
          phoneVerified: true,
        );
      await openProfile(tester, repository: repo);

      expect(find.text('Priya Kumar'), findsWidgets);
      expect(find.text('priya@example.com'), findsWidgets);
      expect(find.text('9876543210'), findsWidgets);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('a phone-only rider shows "Not added" for the email',
        (WidgetTester tester) async {
      final FakeAuthRepository repo = FakeAuthRepository()
        ..profileUser = const AuthUser(
          id: 7,
          name: 'Ravi',
          phone: '9876543210',
          role: UserRole.rider,
          status: UserStatus.pending,
        );
      await openProfile(tester, repository: repo);

      // Scoped to the email row: the vehicle row legitimately reads the same
      // way for a rider who has not filled in a number plate yet, so a bare
      // text match would pass for the wrong reason.
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Email'),
            matching: find.byType(InfoTile),
          ),
          matching: find.text('Not added'),
        ),
        findsOneWidget,
      );
      expect(find.text('Verified'), findsNothing);
    });

    testWidgets('a suspended account is surfaced',
        (WidgetTester tester) async {
      final FakeAuthRepository repo = FakeAuthRepository()
        ..profileUser = const AuthUser(
          id: 7,
          name: 'Ravi',
          phone: '9876543210',
          role: UserRole.customer,
          status: UserStatus.suspended,
        );
      await openProfile(tester, repository: repo);

      expect(find.text('Suspended'), findsWidgets);
    });

    testWidgets('a failed refresh keeps the cached profile and offers a retry',
        (WidgetTester tester) async {
      final FakeAuthRepository repo = FakeAuthRepository()
        ..profileError = const ApiException(kind: ApiErrorKind.network);
      await openProfile(tester, repository: repo);

      expect(
        find.text('No internet connection. Check your connection and try again.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      // Cached data survives the failure.
      expect(find.text('Priya Kumar'), findsWidgets);

      repo.profileError = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsNothing);
      expect(repo.profileCount, 2);
    });

    testWidgets('a dead session bounces back to sign-in',
        (WidgetTester tester) async {
      // The client refreshes on a 401 and clears the session when that fails;
      // the screen must not sit there showing a stale profile.
      final FakeAuthRepository repo = FakeAuthRepository()
        ..profileError =
            const ApiException(kind: ApiErrorKind.unauthenticated);
      _useTallPhone(tester);
      await _pumpApp(
        tester,
        seed: _languageChosen,
        repository: repo,
        session: _testSession(),
      );
      await _settleSplash(tester);
      await tester.tap(find.byIcon(Icons.person_outline_rounded).first);
      await tester.pumpAndSettle();

      // The fake throws directly rather than going through ApiClient, so the
      // session survives here — the screen reports the failure instead.
      expect(find.text('Your session has expired. Please sign in again.'),
          findsOneWidget);
    });

    testWidgets('sign out from the profile clears the session',
        (WidgetTester tester) async {
      final FakeAuthRepository repo = await openProfile(tester);

      // The rider profile carries three rows the customer one did not, so the
      // button is below the fold on a test-sized viewport.
      await tester.ensureVisible(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('You have been signed out'), findsOneWidget);
      expect(repo.signOutCount, 1, reason: 'revoked server-side too');
      expect(_controller.isSignedIn, isFalse);
    });

    testWidgets('the language row opens the language screen',
        (WidgetTester tester) async {
      await openProfile(tester);

      await tester.tap(find.byIcon(Icons.translate_rounded).first);
      await tester.pumpAndSettle();
      expect(find.byType(LanguageScreen), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  group('rider home', () {
    testWidgets('the language can be changed after signing in',
        (WidgetTester tester) async {
      _useTallPhone(tester);
      await _pumpApp(
        tester,
        seed: _languageChosen,
        session: _testSession(),
      );
      await _settleSplash(tester);

      // The language row sits below the duty card and the stats, so it is off
      // the fold on a test-sized viewport.
      await tester.ensureVisible(find.byIcon(Icons.translate_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.translate_rounded).first);
      await tester.pumpAndSettle();
      expect(find.byType(LanguageScreen), findsOneWidget);

      await tester.tap(find.text('தமிழ்'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('தொடரவும்'));
      await tester.pumpAndSettle();

      expect(find.byType(RiderHomeScreen), findsOneWidget);
      expect(find.text('பயணத்திற்குத் தயார்'), findsOneWidget);
    });

    testWidgets('going online sends the duty status the API expects',
        (WidgetTester tester) async {
      _useTallPhone(tester);
      final FakeRiderRepository rider = _approvedRider();
      await _pumpApp(
        tester,
        seed: _languageChosen,
        session: _testSession(),
        riderRepository: rider,
      );
      await _settleSplash(tester);

      expect(find.text('Offline'), findsOneWidget);

      await tester.tap(find.text('Go online'));
      // pump, not pumpAndSettle: once the rider is online the status beacon
      // pulses forever, and settling waits for an animation that by design
      // never ends.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(rider.lastDuty, DutyStatus.available);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Waiting for orders nearby'), findsOneWidget);
    });

    testWidgets('a 403 on going online is reported, not swallowed',
        (WidgetTester tester) async {
      _useTallPhone(tester);
      final FakeRiderRepository rider = _approvedRider()
        ..dutyError = const ApiException(
          kind: ApiErrorKind.forbidden,
          statusCode: 403,
          message:
              'Your licence or insurance has expired. Upload current '
              'documents to go online.',
        );
      await _pumpApp(
        tester,
        seed: _languageChosen,
        session: _testSession(),
        riderRepository: rider,
      );
      await _settleSplash(tester);

      await tester.tap(find.text('Go online'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Your licence or insurance has expired. Upload current documents '
          'to go online.',
        ),
        findsOneWidget,
      );
      // Still offline: the toggle must not lie about a call the API refused.
      expect(find.text('Offline'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // The rider app's whole reason for existing. A customer verifies a code and
  // is done; a rider verifies the same code and is `pending`, and where they
  // land afterwards is the API's decision.
  group('rider gate', () {
    Future<void> signedIn(
      WidgetTester tester,
      FakeRiderRepository rider,
    ) async {
      _useTallPhone(tester);
      await _pumpApp(
        tester,
        seed: _languageChosen,
        session: _testSession(),
        riderRepository: rider,
      );
      await _settleSplash(tester);
    }

    testWidgets('a brand-new rider lands in the onboarding wizard',
        (WidgetTester tester) async {
      await signedIn(tester, FakeRiderRepository());

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(RiderHomeScreen), findsNothing);
      expect(find.text('About you'), findsOneWidget);
    });

    testWidgets('a submitted rider waits rather than working',
        (WidgetTester tester) async {
      await signedIn(
        tester,
        FakeRiderRepository(
          kycStatus: KycStatus.submitted,
          fullName: 'Priya Kumar',
          vehicleType: VehicleType.motorcycle,
          uploaded: _riderDocuments,
        ),
      );

      expect(find.byType(KycDecisionScreen), findsOneWidget);
      expect(find.text('We are verifying your documents'), findsOneWidget);
      expect(find.byType(RiderHomeScreen), findsNothing);
    });

    testWidgets('a rejected rider is told why', (WidgetTester tester) async {
      await signedIn(
        tester,
        FakeRiderRepository(
          kycStatus: KycStatus.rejected,
          fullName: 'Priya Kumar',
          rejectionReason: 'The licence photo was too blurred to read.',
          uploaded: _riderDocuments,
        ),
      );

      expect(find.text('We could not verify you'), findsOneWidget);
      expect(
        find.text('The licence photo was too blurred to read.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'verified but not dispatchable is blocked, not shown the home screen',
        (WidgetTester tester) async {
      // The case a client that recomputed the gate itself would get wrong:
      // KYC says verified, but the API still refuses because the licence has
      // lapsed. `can_accept_orders` is the only field that knows.
      await signedIn(
        tester,
        FakeRiderRepository(
          kycStatus: KycStatus.verified,
          canAcceptOrders: false,
          fullName: 'Priya Kumar',
          uploaded: _riderDocuments,
        )..documentsExpired = true,
      );

      expect(find.byType(RiderHomeScreen), findsNothing);
      expect(find.text('You cannot go online yet'), findsOneWidget);
      expect(
        find.text(
          'Your licence or insurance has expired. Upload current documents '
          'to go online.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('"Fix and submit again" actually reopens the wizard',
        (WidgetTester tester) async {
      // The trap: a rejected rider stays `rejected` server-side until they
      // resubmit, so a button that merely refetched would land them straight
      // back on the screen they were trying to leave.
      await signedIn(
        tester,
        FakeRiderRepository(
          kycStatus: KycStatus.rejected,
          fullName: 'Priya Kumar',
          vehicleType: VehicleType.motorcycle,
          rejectionReason: 'The licence photo was too blurred to read.',
          uploaded: _riderDocuments,
        )..pan = 'ABCDE1234F',
      );

      expect(find.byType(KycDecisionScreen), findsOneWidget);

      await tester.tap(find.text('Fix and submit again'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(KycDecisionScreen), findsNothing);
    });

    testWidgets('expired documents open the checklist, not the whole wizard',
        (WidgetTester tester) async {
      // KYC is verified, so every reference number is locked server-side and
      // the resume logic — seeing a complete file — would drop this rider on
      // the review step. The one thing they can change is the photograph.
      await signedIn(
        tester,
        FakeRiderRepository(
          kycStatus: KycStatus.verified,
          canAcceptOrders: false,
          fullName: 'Priya Kumar',
          vehicleType: VehicleType.motorcycle,
          uploaded: _riderDocuments,
        )
          ..documentsExpired = true
          ..pan = 'ABCDE1234F'
          ..drivingLicenceNo = 'TN01'
          ..insuranceExpiry = DateTime(2030),
      );

      await tester.tap(find.text('Update documents'));
      await tester.pumpAndSettle();

      expect(find.text('Your documents'), findsOneWidget);
      // Verified KYC normally locks the file; expired documents are the one
      // case where re-uploading has to stay open.
      expect(_rider.canEditDocuments, isTrue);
      expect(find.text('Replace'), findsWidgets);
    });

    testWidgets('an approved rider goes straight to work',
        (WidgetTester tester) async {
      await signedIn(tester, _approvedRider());

      expect(find.byType(RiderHomeScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });

    testWidgets('a merchant account is named, without asking the rider API',
        (WidgetTester tester) async {
      // Caught on a real device: signing in with an email that belonged to a
      // merchant. The role is in the otp/verify response, so the app can say
      // so immediately instead of firing a request it knows will 403.
      final FakeRiderRepository rider = FakeRiderRepository();
      _useTallPhone(tester);
      await _pumpApp(
        tester,
        seed: _languageChosen,
        riderRepository: rider,
        session: const AuthSession(
          user: AuthUser(
            id: 5,
            name: 'Joseph Vijay',
            email: 'merchant@example.com',
            role: UserRole.merchant,
            status: UserStatus.active,
          ),
          accessToken: 'a',
          refreshToken: 'r',
          expiresIn: 3600,
        ),
      );
      await _settleSplash(tester);

      expect(find.text('This is not a delivery partner account'),
          findsOneWidget);
      expect(find.textContaining('already registered as a Nexmile merchant'),
          findsOneWidget);
      expect(find.text('Use another account'), findsOneWidget);

      // The whole point: no wasted round-trip to endpoints that are certain
      // to refuse this account.
      expect(rider.profileCount, 0);
    });

    testWidgets('an unrecognised role is allowed through, not locked out',
        (WidgetTester tester) async {
      // A role this build predates must not bar a genuine rider over a backend
      // deploy. It falls through to the request and the 403 handling catches
      // it if the API really does refuse.
      await signedIn(tester, FakeRiderRepository());
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('a customer account is told so, not that KYC is under review',
        (WidgetTester tester) async {
      // Caught on a real device: signing in with an email that already existed
      // as a customer gets a 403 from the role-gated rider routes, and the
      // app told the user "Your documents are still being verified" -- for
      // documents they had never uploaded. A 403 on the profile fetch can only
      // mean the account is not a rider.
      await signedIn(
        tester,
        FakeRiderRepository()
          ..profileError = const ApiException(
            kind: ApiErrorKind.forbidden,
            statusCode: 403,
            message: 'This account is not allowed to access this resource.',
          ),
      );

      expect(_rider.loadFailure, RiderFailure.notARider);
      expect(find.text('This is not a delivery partner account'),
          findsOneWidget);
      // Reached only when the role check let the account through — so the app
      // does not know which role it is and must not name one.
      expect(
        find.textContaining('already registered on another Nexmile account'),
        findsOneWidget,
      );

      // The role is fixed at account creation, so a retry could only ever fail
      // again. The one action offered has to be the one that works.
      expect(find.text('Your documents are still being verified.'),
          findsNothing);
      expect(find.text('Try again'), findsNothing);
      expect(find.text('Use another account'), findsOneWidget);
    });

    testWidgets('a rider with no rider row yet gets the wizard, not an error',
        (WidgetTester tester) async {
      // A 404 means the account exists but onboarding has never been started,
      // so there is no rider row to return. That is the wizard's cue, not a
      // failure -- it is the very first thing a new rider does.
      await signedIn(
        tester,
        FakeRiderRepository()
          ..profileError = const ApiException(
            kind: ApiErrorKind.server,
            statusCode: 404,
          ),
      );

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('About you'), findsOneWidget);
      expect(_rider.loadFailure, isNull);
    });

    testWidgets('a network failure is not reported as a server refusal',
        (WidgetTester tester) async {
      await signedIn(
        tester,
        FakeRiderRepository()
          ..profileError = const ApiException(kind: ApiErrorKind.network),
      );

      expect(_rider.loadFailure, RiderFailure.network);
      expect(
        find.text(
          'No internet connection. Check your connection and try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('a transient failure recovers on retry',
        (WidgetTester tester) async {
      // A 500 is the one case where retrying is genuinely the right advice:
      // nothing about the account is wrong, so the same call may well work a
      // moment later.
      final FakeRiderRepository rider = FakeRiderRepository()
        ..profileError = const ApiException(
          kind: ApiErrorKind.server,
          statusCode: 500,
        );
      await signedIn(tester, rider);

      expect(_rider.loadFailure, RiderFailure.unknown);
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );

      rider.profileError = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(_rider.loadFailure, isNull, reason: 'cleared on success');
    });
  });

  // -------------------------------------------------------------------------
  group('onboarding wizard', () {
    Future<FakeRiderRepository> openWizard(WidgetTester tester) async {
      _useTallPhone(tester);
      final FakeRiderRepository rider = FakeRiderRepository();
      await _pumpApp(
        tester,
        seed: _languageChosen,
        session: _testSession(),
        riderRepository: rider,
      );
      await _settleSplash(tester);
      return rider;
    }

    testWidgets('the first step refuses to advance without a name',
        (WidgetTester tester) async {
      final FakeRiderRepository rider = await openWizard(tester);

      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();

      expect(find.text('This is required'), findsWidgets);
      expect(rider.fullName, isEmpty);
      expect(find.text('About you'), findsOneWidget);
    });

    testWidgets('a name and date of birth advance to the vehicle step',
        (WidgetTester tester) async {
      final FakeRiderRepository rider = await openWizard(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Priya Kumar');
      await tester.pumpAndSettle();

      // Open the date picker and take whatever it offers, which is the newest
      // date the field allows — exactly 18 years ago.
      await tester.tap(find.text('Select a date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();

      expect(rider.fullName, 'Priya Kumar');
      expect(find.text('Your vehicle'), findsOneWidget);
      expect(find.text('Step 2 of 7'), findsOneWidget);
    });

    testWidgets('the number plate is normalised before it is sent',
        (WidgetTester tester) async {
      final FakeRiderRepository rider = await openWizard(tester);
      rider.fullName = 'Priya Kumar';

      // Straight to the vehicle step rather than through the first one — this
      // test is about what leaves the field, not about navigation.
      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Priya Kumar');
      await tester.tap(find.text('Select a date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Motorcycle'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'tn 01 ab-1234',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'RC12345');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();

      expect(rider.vehicleNumber, 'TN01AB1234');
      expect(rider.vehicleType, VehicleType.motorcycle);
      expect(rider.lastDetails?.rcNumber, 'RC12345');
    });

    testWidgets('a malformed PAN is caught before the request goes out',
        (WidgetTester tester) async {
      // Already past the two profile steps, so the wizard resumes on the
      // identity-numbers step — which is what this test is about.
      final FakeRiderRepository rider = FakeRiderRepository(
        fullName: 'Priya Kumar',
        vehicleType: VehicleType.motorcycle,
      );
      _useTallPhone(tester);
      await _pumpApp(
        tester,
        seed: _languageChosen,
        session: _testSession(),
        riderRepository: rider,
      );
      await _settleSplash(tester);

      expect(find.text('Identity numbers'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        '123456789012',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'NOTAPAN');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid PAN, like ABCDE1234F'), findsWidgets);
      expect(rider.detailsCount, 0);
    });

    testWidgets('the documents step lists exactly what the API asked for',
        (WidgetTester tester) async {
      // Past every typed step, nothing uploaded — so the wizard resumes on the
      // document checklist.
      final FakeRiderRepository rider = FakeRiderRepository(
        fullName: 'Priya Kumar',
        vehicleType: VehicleType.motorcycle,
      )
        ..pan = 'ABCDE1234F'
        ..drivingLicenceNo = 'TN0120200001234'
        ..insuranceExpiry = DateTime(2030);
      _useTallPhone(tester);
      await _pumpApp(
        tester,
        seed: _languageChosen,
        session: _testSession(),
        riderRepository: rider,
      );
      await _settleSplash(tester);

      expect(find.text('Your documents'), findsOneWidget);
      expect(find.text('0 of 6 uploaded'), findsOneWidget);

      // The list is the server's `allowed_documents`, rendered through the
      // catalogue's translated names — nothing here is hard-coded in the UI.
      for (final String label in <String>[
        'Aadhaar card (front)',
        'Aadhaar card (back)',
        'Driving licence',
        'Vehicle registration certificate',
        'Vehicle insurance',
        'Profile photo',
      ]) {
        await tester.scrollUntilVisible(find.text(label), 120);
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('the documents step will not advance while one is missing',
        (WidgetTester tester) async {
      // Five of six uploaded: the API's `can_submit` is false and the step
      // must not let the rider walk past it to the review screen.
      final FakeRiderRepository rider = FakeRiderRepository(
        fullName: 'Priya Kumar',
        vehicleType: VehicleType.motorcycle,
        uploaded: _riderDocuments.take(5).toList(),
      )
        ..pan = 'ABCDE1234F'
        ..drivingLicenceNo = 'TN0120200001234'
        ..insuranceExpiry = DateTime(2030);
      _useTallPhone(tester);
      await _pumpApp(
        tester,
        seed: _languageChosen,
        session: _testSession(),
        riderRepository: rider,
      );
      await _settleSplash(tester);

      expect(find.text('Your documents'), findsOneWidget);
      expect(find.text('5 of 6 uploaded'), findsOneWidget);

      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();

      // Still here. The button is disabled rather than hidden, so the rider
      // can see what they are working towards.
      expect(find.text('Your documents'), findsOneWidget);
      expect(find.text('Check and submit'), findsNothing);
    });

    testWidgets('submit stays disabled until the API says can_submit',
        (WidgetTester tester) async {
      // Every document uploaded but no reference numbers on file, so the
      // fake's `can_submit` is false — and the button has to follow it rather
      // than the app's own guess.
      final FakeRiderRepository rider = FakeRiderRepository(
        fullName: 'Priya Kumar',
        vehicleType: VehicleType.motorcycle,
        uploaded: _riderDocuments,
      )
        ..pan = 'ABCDE1234F'
        ..drivingLicenceNo = 'TN0120200001234'
        ..insuranceExpiry = DateTime(2030);
      _useTallPhone(tester);
      await _pumpApp(
        tester,
        seed: _languageChosen,
        session: _testSession(),
        riderRepository: rider,
      );
      await _settleSplash(tester);

      expect(find.text('Check and submit'), findsOneWidget);
      expect(_rider.canSubmit, isFalse);

      await tester.ensureVisible(find.text('Submit for verification'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit for verification'));
      await tester.pumpAndSettle();

      // No confirmation dialog and no call: the button is inert.
      expect(find.text('Submit for verification?'), findsNothing);
      expect(rider.submitCount, 0);
    });

    testWidgets('submitting moves the rider into the waiting room',
        (WidgetTester tester) async {
      // Everything done: eleven detail fields on file and six documents up.
      final FakeRiderRepository rider = FakeRiderRepository(
        fullName: 'Priya Kumar',
        vehicleType: VehicleType.motorcycle,
        uploaded: _riderDocuments,
      )
        ..pan = 'ABCDE1234F'
        ..drivingLicenceNo = 'TN0120200001234'
        ..insuranceExpiry = DateTime(2030);
      rider.savedDetails.addAll(<String, Object?>{
        'aadhaar_number': '123456789012',
        'pan': 'ABCDE1234F',
        'driving_licence_no': 'TN0120200001234',
        'driving_licence_expiry': '2030-01-01',
        'vehicle_number': 'TN01AB1234',
        'rc_number': 'RC12345',
        'insurance_number': 'POL123456',
        'insurance_expiry': '2030-01-01',
        'bank_account_name': 'Priya Kumar',
        'bank_account_number': '123456789012',
        'bank_ifsc': 'SBIN0001234',
      });

      _useTallPhone(tester);
      await _pumpApp(
        tester,
        seed: _languageChosen,
        session: _testSession(),
        riderRepository: rider,
      );
      await _settleSplash(tester);

      // Resume lands on the review step: nothing is missing.
      expect(find.text('Check and submit'), findsOneWidget);
      expect(_rider.canSubmit, isTrue);

      await tester.ensureVisible(find.text('Submit for verification'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit for verification'));
      await tester.pumpAndSettle();

      // Confirmation first — submitting locks the file.
      expect(find.text('Submit for verification?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(rider.submitCount, 0);

      await tester.tap(find.text('Submit for verification'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, 'Submit for verification'),
      );
      await tester.pumpAndSettle();

      expect(rider.submitCount, 1);
      // The gate swaps the body out on its own — no navigation involved.
      expect(find.byType(KycDecisionScreen), findsOneWidget);
      expect(find.text('We are verifying your documents'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  group('API wire log', () {
    /// Captures what `debugPrint` would have written.
    List<String> capture(void Function() body) {
      final List<String> lines = <String>[];
      final DebugPrintCallback original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) lines.add(message);
      };
      try {
        body();
      } finally {
        debugPrint = original;
      }
      return lines;
    }

    test('an OTP code never reaches the log', () {
      final List<String> lines = capture(() {
        ApiLog.request('POST', Uri.parse('https://x/api/v1/auth/otp/verify'),
            <String, dynamic>{
              'phone': '9876543210',
              'code': '123456',
              'device_name': 'test',
            });
      });

      expect(lines.single, contains('/v1/auth/otp/verify'));
      // The number is fine -- it is the identifier the rider typed. The code
      // is a live credential for the next five minutes.
      expect(lines.single, contains('9876543210'));
      expect(lines.single, isNot(contains('123456')));
      expect(lines.single, contains('***(6)'));
    });

    test('tokens and KYC identifiers are masked in responses', () {
      final List<String> lines = capture(() {
        ApiLog.response(
          'POST',
          Uri.parse('https://x/api/v1/auth/otp/verify'),
          200,
          jsonEncode(<String, dynamic>{
            'data': <String, dynamic>{
              'access_token': 'secret-access',
              'refresh_token': 'secret-refresh',
              'user': <String, dynamic>{'id': 7, 'role': 'rider'},
            },
          }),
          const Duration(milliseconds: 120),
        );
      });

      final String line = lines.single;
      expect(line, contains('200'));
      expect(line, contains('120ms'));
      expect(line, contains('rider'), reason: 'the useful part survives');
      expect(line, isNot(contains('secret-access')));
      expect(line, isNot(contains('secret-refresh')));
    });

    test('KYC details are masked wherever they are nested', () {
      final List<String> lines = capture(() {
        ApiLog.request('PATCH', Uri.parse('https://x/api/v1/rider/kyc/details'),
            <String, dynamic>{
              'aadhaar_number': '123456789012',
              'pan': 'ABCDE1234F',
              'bank_account_number': '000123456789',
              'bank_ifsc': 'SBIN0001234',
              'vehicle_number': 'TN01AB1234',
            });
      });

      final String line = lines.single;
      expect(line, isNot(contains('123456789012')));
      expect(line, isNot(contains('ABCDE1234F')));
      expect(line, isNot(contains('000123456789')));
      expect(line, isNot(contains('SBIN0001234')));
      // A number plate is not a secret and is genuinely useful when a save is
      // being rejected.
      expect(line, contains('TN01AB1234'));
    });

    test('a non-JSON error page is summarised, not dumped', () {
      final List<String> lines = capture(() {
        ApiLog.response(
          'GET',
          Uri.parse('https://x/api/v1/rider/profile'),
          500,
          '<html>${'x' * 5000}</html>',
          const Duration(milliseconds: 30),
        );
      });

      expect(lines.single, contains('not JSON'));
      expect(lines.single.length, lessThan(200));
      expect(lines.single, startsWith('✗ 500'));
    });

    test('an upload logs its size but never its bytes', () {
      final List<String> lines = capture(() {
        ApiLog.upload(
          Uri.parse('https://x/api/v1/rider/kyc/documents'),
          <String, String>{'type': 'driving_licence'},
          'licence.jpg',
          204800,
        );
      });

      expect(lines.single, contains('driving_licence'));
      expect(lines.single, contains('licence.jpg'));
      expect(lines.single, contains('200KB'));
    });
  });

  // -------------------------------------------------------------------------
  group('KYC validators', () {
    late AppLocalizations l10n;

    setUp(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('Aadhaar takes exactly twelve digits', () {
      expect(KycValidators.aadhaar('123456789012', l10n), isNull);
      expect(KycValidators.aadhaar('1234 5678 9012', l10n), isNull);
      expect(KycValidators.aadhaar('12345678901', l10n), isNotNull);
      expect(KycValidators.aadhaar('12345678901A', l10n), isNotNull);
      expect(KycValidators.aadhaar('', l10n), isNotNull);
    });

    test('PAN follows the five-four-one shape', () {
      expect(KycValidators.pan('ABCDE1234F', l10n), isNull);
      expect(KycValidators.pan('abcde1234f', l10n), isNull);
      expect(KycValidators.pan('ABCD1234F', l10n), isNotNull);
      expect(KycValidators.pan('ABCDE12345', l10n), isNotNull);
    });

    test('IFSC has a zero in the fifth position', () {
      expect(KycValidators.ifsc('SBIN0001234', l10n), isNull);
      expect(KycValidators.ifsc('SBIN1001234', l10n), isNotNull);
      expect(KycValidators.ifsc('SBI0001234', l10n), isNotNull);
    });

    test('a number plate loses its spaces and hyphens', () {
      expect(KycValidators.normalisePlate('tn 01 ab-1234'), 'TN01AB1234');
      expect(KycValidators.normalisePlate('TN01AB1234'), 'TN01AB1234');
      expect(KycValidators.vehicleNumber('tn 01 ab 1234', l10n), isNull);
      expect(KycValidators.vehicleNumber('TN@01', l10n), isNotNull);
    });

    test('an expiry in the past is refused', () {
      final DateTime yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      final DateTime nextYear = DateTime.now().add(const Duration(days: 365));
      expect(KycValidators.futureDate(yesterday, l10n), isNotNull);
      expect(KycValidators.futureDate(nextYear, l10n), isNull);
      expect(KycValidators.futureDate(null, l10n), isNotNull);
    });

    test('a rider under eighteen is refused', () {
      final DateTime now = DateTime.now();
      final DateTime seventeen = DateTime(now.year - 17, now.month, now.day);
      final DateTime nineteen = DateTime(now.year - 19, now.month, now.day);
      expect(KycValidators.adultBirthDate(seventeen, l10n), isNotNull);
      expect(KycValidators.adultBirthDate(nineteen, l10n), isNull);
    });
  });

  // -------------------------------------------------------------------------
  group('KYC decoding', () {
    test('an unknown status degrades rather than throwing', () {
      final KycOverview overview = KycOverview.fromJson(<String, dynamic>{
        'status': 'escalated_to_legal',
        'rejection_reason': null,
        'verified_at': null,
        'required_documents': '6 documents',
        'allowed_documents': <String>['aadhaar_front'],
        'missing_documents': <String>['aadhaar_front'],
        'can_submit': false,
        'documents': <Object?>[],
      });

      expect(overview.status, KycStatus.unknown);
      // Unknown is treated as editable, which shows the wizard rather than a
      // live order screen — the safe direction to be wrong in.
      expect(overview.status.isEditable, isTrue);
    });

    test('documents keyed by slug decode as well as a plain list', () {
      final KycOverview overview = KycOverview.fromJson(<String, dynamic>{
        'status': 'pending',
        'rejection_reason': null,
        'verified_at': null,
        'required_documents': '',
        // A Laravel resource that keys by slug arrives as a map, not a list.
        'allowed_documents': <String, Object?>{
          'aadhaar_front': 'Aadhaar card (front)',
          'rc': 'Vehicle registration certificate',
        },
        'missing_documents': <String>['rc'],
        'can_submit': false,
        'documents': <Object?>[],
      });

      expect(overview.allowedDocuments, <String>['aadhaar_front', 'rc']);
      expect(overview.missingDocuments, <String>['rc']);
    });

    test('duty status crosses the wire as snake_case', () {
      expect(DutyStatus.onBreak.wireValue, 'on_break');
      expect(DutyStatus.fromWire('on_break'), DutyStatus.onBreak);
      expect(DutyStatus.fromWire('nonsense'), DutyStatus.unknown);
      // Unknown must never read as "available" — the fallback decides whether
      // a rider in an unrecognised state can be dispatched.
      expect(DutyStatus.unknown.wireValue, 'offline');
    });

    test('a document type the catalogue has never seen still renders', () {
      expect(
        DocumentCatalogue.presentationOf('police_verification').icon,
        isNotNull,
      );
      // Slug spelling varies; the catalogue folds the common variants.
      expect(
        DocumentCatalogue.presentationOf('driving-licence').icon,
        DocumentCatalogue.presentationOf('driving_licence').icon,
      );
    });

    test('KycDetails omits what was never filled in', () {
      // A partial save must not blank a value an earlier step stored.
      const KycDetails details = KycDetails(pan: 'ABCDE1234F');
      expect(details.toJson(), <String, Object?>{'pan': 'ABCDE1234F'});
    });
  });

  // -------------------------------------------------------------------------
  group('layout robustness', () {
    // The brief: no overlapping or clipped text in any language. Flutter
    // surfaces both as overflow exceptions, so a clean pump of every screen in
    // every locale — and at the extremes of viewport and text scale — is the
    // check.
    testWidgets('login and OTP lay out cleanly in every locale',
        (WidgetTester tester) async {
      _useTallPhone(tester);
      for (final AppLanguage language in AppLanguages.all) {
        await _pumpApp(tester, seed: _languageChosenAs(language.code));
        await _settleSplash(tester);

        expect(find.byType(LoginScreen), findsOneWidget,
            reason: language.englishName);
        expect(tester.takeException(), isNull,
            reason: 'login overflowed in ${language.englishName}');

        _nav(tester).pushNamed(
          AppRoutes.otpVerification,
          arguments: OtpArgs(
            identifier: LoginIdentifier.tryParse('9876543210')!,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'OTP overflowed in ${language.englishName}');
        _nav(tester).pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('the profile screen lays out cleanly in every locale',
        (WidgetTester tester) async {
      _useTallPhone(tester);
      for (final AppLanguage language in AppLanguages.all) {
        await _pumpApp(
          tester,
          seed: _languageChosenAs(language.code),
          session: _testSession(),
        );
        await _settleSplash(tester);

        _nav(tester).pushNamed(AppRoutes.profile);
        await tester.pumpAndSettle();

        expect(find.byType(ProfileScreen), findsOneWidget,
            reason: language.englishName);
        expect(tester.takeException(), isNull,
            reason: 'profile overflowed in ${language.englishName}');
      }
    });

    testWidgets('every onboarding step lays out cleanly in every locale',
        (WidgetTester tester) async {
      // The wizard is where the risk actually is: seven screens of long
      // translated field labels, and the two locales the API supports beyond
      // English are Tamil and Hindi, both of which stack vowel marks.
      _useTallPhone(tester);
      for (final AppLanguage language in AppLanguages.all) {
        await _pumpApp(
          tester,
          seed: _languageChosenAs(language.code),
          session: _testSession(),
          riderRepository: FakeRiderRepository(),
        );
        await _settleSplash(tester);

        expect(find.byType(OnboardingScreen), findsOneWidget,
            reason: language.englishName);
        expect(tester.takeException(), isNull,
            reason: 'step 1 overflowed in ${language.englishName}');

        // Walk the rest by seeding the repository forward, which is how the
        // wizard's resume logic picks a step.
        for (final FakeRiderRepository seeded in <FakeRiderRepository>[
          FakeRiderRepository(fullName: 'Priya Kumar'),
          FakeRiderRepository(
            fullName: 'Priya Kumar',
            vehicleType: VehicleType.motorcycle,
          ),
          FakeRiderRepository(
            fullName: 'Priya Kumar',
            vehicleType: VehicleType.motorcycle,
          )..pan = 'ABCDE1234F',
          FakeRiderRepository(
            fullName: 'Priya Kumar',
            vehicleType: VehicleType.motorcycle,
          )
            ..pan = 'ABCDE1234F'
            ..drivingLicenceNo = 'TN01'
            ..insuranceExpiry = DateTime(2030),
          FakeRiderRepository(
            fullName: 'Priya Kumar',
            vehicleType: VehicleType.motorcycle,
            uploaded: _riderDocuments,
          )
            ..pan = 'ABCDE1234F'
            ..drivingLicenceNo = 'TN01'
            ..insuranceExpiry = DateTime(2030),
        ]) {
          await _pumpApp(
            tester,
            seed: _languageChosenAs(language.code),
            session: _testSession(),
            riderRepository: seeded,
          );
          await _settleSplash(tester);
          expect(tester.takeException(), isNull,
              reason: 'a wizard step overflowed in ${language.englishName}');
        }
      }
    });

    testWidgets('the waiting and rejected screens lay out cleanly',
        (WidgetTester tester) async {
      _useTallPhone(tester);
      for (final AppLanguage language in AppLanguages.all) {
        for (final FakeRiderRepository state in <FakeRiderRepository>[
          FakeRiderRepository(
            kycStatus: KycStatus.submitted,
            fullName: 'Priya Kumar',
            uploaded: _riderDocuments,
          ),
          FakeRiderRepository(
            kycStatus: KycStatus.rejected,
            fullName: 'Priya Kumar',
            rejectionReason: 'The licence photo was too blurred to read.',
            uploaded: _riderDocuments,
          ),
        ]) {
          await _pumpApp(
            tester,
            seed: _languageChosenAs(language.code),
            session: _testSession(),
            riderRepository: state,
          );
          await _settleSplash(tester);

          expect(find.byType(KycDecisionScreen), findsOneWidget,
              reason: language.englishName);
          expect(tester.takeException(), isNull,
              reason: 'decision screen overflowed in ${language.englishName}');
        }
      }
    });

    testWidgets('the language screen lays out cleanly in every locale',
        (WidgetTester tester) async {
      for (final AppLanguage language in AppLanguages.all) {
        await _pumpApp(
          tester,
          seed: <String, Object>{'nexmile.language_code': language.code},
        );
        await _settleSplash(tester);

        expect(find.byType(LanguageScreen), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: '${language.englishName} overflowed');
      }
    });

    testWidgets('login holds up on 320x568 at maximum text scale',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 3.0; // clamps to 1.3
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await _pumpApp(tester, seed: _languageChosenAs('ta'));
      await _settleSplash(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the dashboard holds up on 320x568 at maximum text scale',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await _pumpApp(
        tester,
        seed: _languageChosenAs('ml'),
        session: _testSession(),
      );
      await _settleSplash(tester);

      expect(find.byType(RiderHomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('right-to-left languages flip the layout',
        (WidgetTester tester) async {
      await _pumpApp(tester, seed: _languageChosenAs('ur'));
      await _settleSplash(tester);

      final Directionality directionality = tester.widget<Directionality>(
        find.byType(Directionality).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Minimal [TokenProvider] for the [ApiClient] tests.
class _StubTokens implements TokenProvider {
  _StubTokens(this._token, {this.refreshResult = true});

  final String _token;
  final bool refreshResult;

  int refreshCalls = 0;
  int sessionLostCalls = 0;

  @override
  String? get accessToken => _token;

  @override
  Future<bool> refresh() async {
    refreshCalls++;
    // A real refresh is a network round trip; the delay is what makes the
    // single-flight assertion meaningful.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return refreshResult;
  }

  @override
  Future<void> onSessionLost() async => sessionLostCalls++;
}
