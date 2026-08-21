import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../generated/l10n/app_localizations.dart';
import '../../../data/rider_failure.dart';
import '../../../state/order_controller.dart';

/// Handing an order back to the board.
///
/// The reason is optional on the wire and optional here. Making it mandatory
/// would produce a screen full of "." — a rider with a puncture is not in a
/// position to compose an explanation, and the order needs to get back on the
/// board either way.
class ReleaseOrderSheet extends StatefulWidget {
  const ReleaseOrderSheet({super.key, required this.orderId});

  final String orderId;

  /// Returns true when the order was handed back.
  static Future<bool> show(BuildContext context, String orderId) async {
    final bool? released = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ReleaseOrderSheet(orderId: orderId),
    );
    return released ?? false;
  }

  @override
  State<ReleaseOrderSheet> createState() => _ReleaseOrderSheetState();
}

class _ReleaseOrderSheetState extends State<ReleaseOrderSheet> {
  final TextEditingController _reason = TextEditingController();

  RiderFailure? _failure;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final OrderController orders = context.read<OrderController>();
    final String reason = _reason.text.trim();

    setState(() => _failure = null);
    final RiderFailure? failure = await orders.release(
      widget.orderId,
      reason: reason.isEmpty ? null : reason,
    );

    if (!mounted) return;
    if (failure == null) {
      navigator.pop(true);
      return;
    }
    setState(() => _failure = failure);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OrderController orders = context.watch<OrderController>();

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            l10n.releaseOrderTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.releaseOrderBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          TextField(
            controller: _reason,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            maxLength: 255,
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              hintText: l10n.releaseReasonHint,
              counterText: '',
              errorText: _failure?.message(l10n),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: orders.isActing
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                  ),
                  child: Text(
                    l10n.cancelLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: orders.isActing ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  child: Text(
                    l10n.releaseOrderButton,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
