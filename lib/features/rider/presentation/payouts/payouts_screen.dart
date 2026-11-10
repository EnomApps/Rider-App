import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_surface.dart';
import '../../../../core/widgets/info_tile.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../data/payout_models.dart';
import '../../data/rider_failure.dart';
import '../../state/payout_controller.dart';
import '../orders/order_formatting.dart';
import '../orders/widgets/order_empty_state.dart';
import 'payout_details_screen.dart';
import 'payout_formatting.dart';

/// Week by week, what the rider is owed and whether it has been sent.
class PayoutsScreen extends StatefulWidget {
  const PayoutsScreen({super.key});

  @override
  State<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends State<PayoutsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PayoutController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PayoutController controller = context.watch<PayoutController>();
    final List<Payout> payouts = controller.payouts;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.payoutsTitle)),
      body: RefreshIndicator(
        onRefresh: () => controller.load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            if (controller.failure != null) ...<Widget>[
              OrderBanner(message: controller.failure!.message(l10n)),
              const SizedBox(height: 16),
            ],
            if (!controller.hasLoaded && payouts.isEmpty)
              controller.failure == null
                  ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                  : const SizedBox.shrink()
            else if (payouts.isEmpty)
              OrderEmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: l10n.payoutsEmptyTitle,
                body: l10n.payoutsEmptyBody,
              )
            else
              for (final Payout payout in payouts) ...<Widget>[
                _PayoutCard(
                  payout: payout,
                  onTap:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PayoutDetailsScreen(payout: payout),
                        ),
                      ),
                ),
                const SizedBox(height: 14),
              ],
          ],
        ),
      ),
    );
  }
}

/// One week: the dates, the status, and the amount payable.
class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.payout, required this.onTap});

  final Payout payout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return SurfaceCard(
      radius: AppSurface.radiusLarge,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  payout.periodText(context, l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                StatusChip(
                  label: payout.statusText(l10n),
                  tone: payout.statusTone,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                formatAmount(l10n, payout.net),
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(l10n.payoutNetLabel, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
