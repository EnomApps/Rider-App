import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/push/push_service.dart';
import '../../../../core/services/device_setup.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../generated/l10n/app_localizations.dart';

/// Phone brands that close background apps unless Autostart is switched on,
/// a setting no app can read or change for the rider.
const Set<String> _autostartBrands = <String>{
  'xiaomi',
  'redmi',
  'poco',
  'oppo',
  'realme',
  'vivo',
  'iqoo',
  'oneplus',
  'samsung',
};

const String _autostartKey = 'nexmile.autostart_confirmed';

/// Where each setup step stands.
@immutable
class PhoneSetupStatus {
  const PhoneSetupStatus({
    required this.notifications,
    required this.fullScreen,
    required this.location,
    required this.battery,
    required this.brand,
    required this.autostartConfirmed,
  });

  final bool notifications;
  final bool fullScreen;
  final bool location;
  final bool battery;

  /// The phone's maker, or empty off Android.
  final String brand;
  final bool autostartConfirmed;

  bool get needsAutostart =>
      _autostartBrands.contains(brand.trim().toLowerCase());

  /// Steps still to do. Autostart counts only on the brands that need it.
  int get missing => <bool>[
        notifications,
        fullScreen,
        location,
        battery,
        if (needsAutostart) autostartConfirmed,
      ].where((bool done) => !done).length;

  static Future<PhoneSetupStatus> check(
    PushService push, {
    DeviceSetup device = const DeviceSetup(),
  }) async {
    final LocationPermission permission = await _safe(
      Geolocator.checkPermission,
      LocationPermission.denied,
    );
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return PhoneSetupStatus(
      notifications: await _safe(push.notificationsAllowed, false),
      fullScreen: await device.canUseFullScreenIntent(),
      location: permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always,
      battery: await device.isIgnoringBatteryOptimizations(),
      brand: await device.manufacturer(),
      autostartConfirmed: prefs.getBool(_autostartKey) ?? false,
    );
  }

  static Future<T> _safe<T>(Future<T> Function() read, T fallback) async {
    try {
      return await read();
    } catch (_) {
      return fallback;
    }
  }
}

/// One guided screen for every phone setting an order alert depends on.
///
/// A rider who finishes onboarding with two of these missing looks, from the
/// outside, exactly like a backend that does not send orders, so each step
/// says plainly why it matters and takes the rider straight to the setting.
/// The list re-checks itself whenever the rider comes back from Settings.
class PhoneSetupScreen extends StatefulWidget {
  const PhoneSetupScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PhoneSetupScreen()),
      );

  @override
  State<PhoneSetupScreen> createState() => _PhoneSetupScreenState();
}

class _PhoneSetupScreenState extends State<PhoneSetupScreen>
    with WidgetsBindingObserver {
  static const DeviceSetup _device = DeviceSetup();
  PhoneSetupStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final PhoneSetupStatus status =
        await PhoneSetupStatus.check(context.read<PushService>());
    if (mounted) setState(() => _status = status);
  }

  Future<void> _then(Future<Object?> action) async {
    await action;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final PhoneSetupStatus? s = _status;
    final PushService push = context.read<PushService>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupTitle)),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: <Widget>[
                Text(l10n.setupIntro, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 20),
                _Step(
                  icon: Icons.notifications_active_outlined,
                  title: l10n.setupNotifications,
                  body: l10n.setupNotificationsBody,
                  done: s.notifications,
                  actionLabel: l10n.setupAllow,
                  onAction: () => _then(push.requestPermission()),
                ),
                _Step(
                  icon: Icons.fullscreen_rounded,
                  title: l10n.setupFullScreen,
                  body: l10n.setupFullScreenBody,
                  done: s.fullScreen,
                  actionLabel: l10n.setupOpenSettings,
                  onAction: () => _then(_device.openFullScreenIntentSettings()),
                ),
                _Step(
                  icon: Icons.my_location_rounded,
                  title: l10n.setupLocation,
                  body: l10n.setupLocationBody,
                  done: s.location,
                  actionLabel: l10n.setupAllow,
                  onAction: () => _then(() async {
                    final LocationPermission now =
                        await Geolocator.checkPermission();
                    if (now == LocationPermission.deniedForever) {
                      await Geolocator.openAppSettings();
                    } else {
                      await Geolocator.requestPermission();
                    }
                  }()),
                ),
                _Step(
                  icon: Icons.battery_charging_full_rounded,
                  title: l10n.setupBattery,
                  body: l10n.setupBatteryBody,
                  done: s.battery,
                  actionLabel: l10n.setupAllow,
                  onAction: () =>
                      _then(_device.requestIgnoreBatteryOptimizations()),
                ),
                if (s.needsAutostart)
                  _Step(
                    icon: Icons.rocket_launch_outlined,
                    title: l10n.setupAutostart,
                    body: l10n.setupAutostartBody(_titleCase(s.brand)),
                    done: s.autostartConfirmed,
                    actionLabel: l10n.setupOpenSettings,
                    onAction: () => _then(_device.openAppSettings()),
                    // No app can read this setting, so the rider says so.
                    secondaryLabel: l10n.setupMarkDone,
                    onSecondary: () => _then(() async {
                      final SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setBool(_autostartKey, true);
                    }()),
                  ),
              ],
            ),
    );
  }

  static String _titleCase(String brand) => brand.isEmpty
      ? brand
      : brand[0].toUpperCase() + brand.substring(1).toLowerCase();
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.title,
    required this.body,
    required this.done,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool done;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: done
            ? AppColors.greenDeep.withValues(alpha: 0.06)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: done
              ? AppColors.greenDeep.withValues(alpha: 0.35)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            done ? Icons.check_circle_rounded : icon,
            color: done ? AppColors.greenDeep : theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodyMedium),
                if (!done) ...<Widget>[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      FilledButton(
                        onPressed: onAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.greenDeep,
                        ),
                        child: Text(actionLabel),
                      ),
                      if (secondaryLabel != null)
                        OutlinedButton(
                          onPressed: onSecondary,
                          child: Text(secondaryLabel!),
                        ),
                    ],
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l10n.setupDoneStep,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.greenDeep,
                        fontWeight: FontWeight.w700,
                      ),
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

/// "Finish phone setup — 2 left", on the board until every step is done.
/// Re-checks on resume, so it disappears the moment the last setting lands.
class PhoneSetupBanner extends StatefulWidget {
  const PhoneSetupBanner({super.key});

  @override
  State<PhoneSetupBanner> createState() => _PhoneSetupBannerState();
}

class _PhoneSetupBannerState extends State<PhoneSetupBanner>
    with WidgetsBindingObserver {
  int _missing = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    // Only Android has these settings; elsewhere the banner never shows.
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final PhoneSetupStatus status =
        await PhoneSetupStatus.check(context.read<PushService>());
    if (mounted) setState(() => _missing = status.missing);
  }

  @override
  Widget build(BuildContext context) {
    if (_missing == 0) return const SizedBox.shrink();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.orangeDeep.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () async {
            await PhoneSetupScreen.open(context);
            await _refresh();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                const Icon(Icons.phonelink_setup_rounded,
                    color: AppColors.orangeDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.setupBannerTitle,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        l10n.setupBannerBody('$_missing'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
