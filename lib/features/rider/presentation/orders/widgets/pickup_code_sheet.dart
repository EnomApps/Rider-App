import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../generated/l10n/app_localizations.dart';
import '../../../data/rider_failure.dart';
import '../../../state/order_controller.dart';

/// Where the merchant's code is typed.
///
/// A sheet rather than a screen, and a sheet the rider is not thrown out of on
/// a wrong code: the failure lands on the field and the keyboard stays up,
/// because being told "that did not match" while looking at the counter is the
/// moment to ask the merchant to read it again.
///
/// There is deliberately no way past this without a code. It is the evidence a
/// disputed delivery is settled with, so an "I collected it anyway" escape
/// hatch would defeat the only record that the handover happened.
class PickupCodeSheet extends StatefulWidget {
  const PickupCodeSheet({super.key, required this.orderId});

  final String orderId;

  /// Returns true when the pickup was confirmed.
  static Future<bool> show(BuildContext context, String orderId) async {
    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PickupCodeSheet(orderId: orderId),
    );
    return confirmed ?? false;
  }

  @override
  State<PickupCodeSheet> createState() => _PickupCodeSheetState();
}

class _PickupCodeSheetState extends State<PickupCodeSheet> {
  final TextEditingController _code = TextEditingController();
  final FocusNode _focus = FocusNode();

  RiderFailure? _failure;

  @override
  void initState() {
    super.initState();
    // The rider is already holding the phone up to be read to; opening the
    // keyboard with the sheet saves the extra tap.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _failure = RiderFailure.wrongPickupCode);
      return;
    }

    final NavigatorState navigator = Navigator.of(context);
    final OrderController orders = context.read<OrderController>();

    setState(() => _failure = null);
    final RiderFailure? failure = await orders.confirmPickup(
      widget.orderId,
      code,
    );

    if (!mounted) return;
    if (failure == null) {
      navigator.pop(true);
      return;
    }

    setState(() => _failure = failure);
    // An order that is no longer this rider's cannot be picked up by retyping
    // anything, so that one closes the sheet — the screen behind it will have
    // already dropped back to the board.
    if (failure == RiderFailure.orderGone) navigator.pop(false);
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
        // Clears the keyboard the sheet just opened.
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
            l10n.pickupCodeTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.pickupCodeSubtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          TextField(
            controller: _code,
            focusNode: _focus,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            // Always left-to-right: a code is digits, and mirroring it in an
            // RTL locale would have the rider reading it back wrong.
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            // The schema caps it at eight; four is what merchants read out.
            maxLength: 8,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: l10n.pickupCodeHint,
              counterText: '',
              errorText: _failure?.message(l10n),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: l10n.confirmPickupButton,
            onPressed: orders.isActing ? null : _submit,
          ),
        ],
      ),
    );
  }
}
