import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../generated/l10n/app_localizations.dart';
import '../../data/order_models.dart';
import '../../data/rider_failure.dart';
import '../../state/order_controller.dart';
import 'order_details_screen.dart';
import 'widgets/order_card.dart';
import 'widgets/order_empty_state.dart';

/// What the rider has already done.
///
/// Fetched once when the tab is opened rather than polled: a finished delivery
/// does not change, and the only new row is one this app itself just created.
class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderController>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OrderController orders = context.watch<OrderController>();
    final List<RiderOrder> history = orders.history;

    return RefreshIndicator(
      onRefresh: () => orders.loadHistory(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          Text(l10n.historyTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 18),

          if (orders.historyFailure != null) ...<Widget>[
            OrderBanner(message: orders.historyFailure!.message(l10n)),
            const SizedBox(height: 16),
          ],

          if (orders.isLoadingHistory && history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (history.isEmpty)
            OrderEmptyState(
              icon: Icons.history_rounded,
              title: l10n.historyEmptyTitle,
              body: l10n.historyEmptyBody,
            )
          else
            for (final RiderOrder order in history) ...<Widget>[
              OrderCard(
                order: order,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrderDetailsScreen(order: order),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}
