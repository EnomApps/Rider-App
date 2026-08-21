import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_language.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/info_tile.dart';
import '../../generated/l10n/app_localizations.dart';
import '../auth/data/auth_failure.dart';
import '../auth/data/auth_user.dart';
import '../auth/state/auth_controller.dart';
import '../rider/data/kyc_models.dart';
import '../rider/data/rider_profile.dart';
import '../rider/state/order_controller.dart';
import '../rider/state/rider_controller.dart';

/// Rider profile, backed by `GET /v1/profile` and the already-loaded
/// `RiderResource`.
///
/// Renders the cached user immediately and refreshes in the background, so the
/// screen is never blank on a slow connection. A failed refresh shows a banner
/// above the still-valid cached data rather than replacing it — the rider's
/// name and number do not stop being true because the network dropped.
///
/// Read-only for now: `PATCH /v1/profile` exists (name, email, phone,
/// preferred_locale) and an edit screen can hang off the same controller.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  AuthFailure? _failure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted || _isLoading) return;
    setState(() => _isLoading = true);

    final NavigatorState navigator = Navigator.of(context);
    final AuthController auth = context.read<AuthController>();
    final AuthFailure? failure = await auth.loadProfile();

    if (!mounted) return;

    // The API client refreshes on a 401 and clears the session if that fails.
    if (!auth.isSignedIn) {
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (Route<void> route) => false,
      );
      return;
    }

    setState(() {
      _isLoading = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AuthUser? user = context.watch<AuthController>().user;
    final AppLanguage language = context.watch<LocaleController>().language;
    // Already in memory — the gate fetched it before this screen could be
    // reached. Null only when the profile is opened from the error state.
    final RiderProfile? rider = context.watch<RiderController>().profile;

    if (user == null) {
      // Only reachable for a blink between sign-out and the route swap.
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: <Widget>[
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          // Always scrollable so pull-to-refresh works even when the content
          // is shorter than the viewport.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: <Widget>[
            _ProfileHeader(user: user),
            const SizedBox(height: 24),
            if (_failure != null) ...<Widget>[
              _RefreshFailedBanner(
                message: _failure!.message(l10n),
                onRetry: _isLoading ? null : _load,
              ),
              const SizedBox(height: 16),
            ],
            InfoTile(
              icon: Icons.person_outline_rounded,
              label: l10n.nameLabel,
              value: user.name.trim().isEmpty ? l10n.notProvided : user.name,
              emphasise: user.name.trim().isNotEmpty,
            ),
            const SizedBox(height: 12),
            InfoTile(
              icon: Icons.alternate_email_rounded,
              label: l10n.emailLabel,
              value: user.email ?? l10n.notProvided,
              emphasise: user.email != null,
              // An address is LTR whatever the app's direction is.
              valueDirection:
                  user.email == null ? null : TextDirection.ltr,
            ),
            const SizedBox(height: 12),
            InfoTile(
              icon: Icons.phone_outlined,
              label: l10n.mobileLabel,
              value: user.phone ?? l10n.notProvided,
              emphasise: user.phone != null,
              valueDirection:
                  user.phone == null ? null : TextDirection.ltr,
              trailing: user.phone != null && user.phoneVerified
                  ? StatusChip(
                      label: l10n.verifiedLabel,
                      tone: StatusTone.positive,
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            InfoTile(
              icon: Icons.verified_user_outlined,
              label: l10n.accountStatusLabel,
              value: _statusLabel(user.status, l10n),
              trailing: StatusChip(
                label: _statusLabel(user.status, l10n),
                tone: _statusTone(user.status),
              ),
            ),
            if (rider != null) ...<Widget>[
              const SizedBox(height: 12),
              InfoTile(
                icon: Icons.verified_user_outlined,
                label: l10n.kycStatusLabel,
                // The chip carries the status on its own; repeating it as the
                // value would put the same word in the row twice.
                value: '',
                trailing: StatusChip(
                  label: _kycLabel(rider.kyc.status, l10n),
                  tone: _kycTone(rider.kyc.status),
                ),
              ),
              const SizedBox(height: 12),
              InfoTile(
                icon: Icons.two_wheeler_outlined,
                label: l10n.vehicleLabel,
                value: rider.vehicleNumber ?? l10n.notProvided,
                emphasise: rider.vehicleNumber != null,
                valueDirection:
                    rider.vehicleNumber == null ? null : TextDirection.ltr,
              ),
              const SizedBox(height: 12),
              InfoTile(
                icon: Icons.local_shipping_outlined,
                label: l10n.completedDeliveriesLabel,
                value: '${rider.completedDeliveries}',
                valueDirection: TextDirection.ltr,
              ),
            ],
            const SizedBox(height: 12),
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
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(l10n.signOut),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.45),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    final RiderController rider = context.read<RiderController>();
    final OrderController orders = context.read<OrderController>();

    await context.read<AuthController>().signOut();
    // Dropped before navigating, so the next rider to sign in on this device
    // never sees the previous one's KYC file on the way to their own.
    rider.reset();
    // Stops the board poll and the position heartbeat as well as dropping
    // the order. A timer that outlived its session would keep a signed-out
    // rider on the dispatch map.
    orders.reset();
    if (!mounted) return;

    navigator.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (Route<void> route) => false,
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.signedOut)));
  }

  static String _statusLabel(UserStatus status, AppLocalizations l10n) {
    switch (status) {
      case UserStatus.active:
        return l10n.statusActive;
      case UserStatus.pending:
        return l10n.statusPending;
      case UserStatus.suspended:
        return l10n.statusSuspended;
      case UserStatus.unknown:
        // The API grew a status this build predates.
        return l10n.notProvided;
    }
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

  static StatusTone _kycTone(KycStatus status) {
    switch (status) {
      case KycStatus.verified:
        return StatusTone.positive;
      case KycStatus.rejected:
        return StatusTone.negative;
      case KycStatus.submitted:
      case KycStatus.pending:
      case KycStatus.unknown:
        return StatusTone.warning;
    }
  }

  static StatusTone _statusTone(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return StatusTone.positive;
      case UserStatus.pending:
      case UserStatus.unknown:
        return StatusTone.warning;
      case UserStatus.suspended:
        return StatusTone.negative;
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String initial =
        user.firstName.isEmpty ? '?' : user.firstName.characters.first.toUpperCase();

    return Column(
      children: <Widget>[
        Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: AppColors.greenGradient,
            shape: BoxShape.circle,
          ),
          child: Text(
            initial,
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          user.name.trim().isEmpty
              ? (user.email ?? user.phone ?? '')
              : user.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          user.email ?? user.phone ?? '',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _RefreshFailedBanner extends StatelessWidget {
  const _RefreshFailedBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foreground = theme.colorScheme.error;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.cloud_off_rounded, size: 19, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: foreground,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 40),
            ),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
