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
import '../../data/rider_failure.dart';
import '../../data/rider_profile.dart';
import '../../state/rider_controller.dart';

/// The main UI, reached only when `can_accept_orders` is true.
///
/// A rider who has not been approved never sees this screen — the gate hands
/// them the wizard or the waiting room instead — so nothing here has to defend
/// against an unverified account. What it does defend against is the API
/// changing its mind mid-session: a licence that lapses while the rider is
/// online makes the next duty-status call fail, and the toggle reports that
/// rather than silently staying on.
class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppLanguage language = context.watch<LocaleController>().language;
    final AuthUser? user = context.watch<AuthController>().user;
    final RiderController rider = context.watch<RiderController>();
    final RiderProfile? profile = rider.profile;

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
      body: RefreshIndicator(
        onRefresh: () => rider.refresh(),
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
    final bool isDark = theme.brightness == Brightness.dark;

    final bool online = profile.dutyStatus == DutyStatus.available;
    final bool onBreak = profile.dutyStatus == DutyStatus.onBreak;

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
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  onPressed: rider.isSaving
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
                    onPressed: rider.isSaving
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
  /// often. Surfaced verbatim rather than swallowed, because it is the only
  /// warning the rider gets before a shift they cannot work.
  Future<void> _set(BuildContext context, DutyStatus status) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RiderController rider = context.read<RiderController>();

    final RiderFailure? failure = await rider.setDutyStatus(status);
    if (failure == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(failure.message(l10n)),
          duration: const Duration(seconds: 6),
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
