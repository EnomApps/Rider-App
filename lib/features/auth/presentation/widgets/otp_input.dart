import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// Six-box OTP entry.
///
/// Implemented as *one* hidden [TextField] with the boxes painted from its
/// value, rather than six separate fields. Six fields have to hand focus back
/// and forth on every keystroke, which breaks backspace, breaks pasting a code,
/// and breaks the platform's SMS autofill. With a single field all three come
/// for free: [AutofillHints.oneTimeCode] lets Android and iOS drop the code
/// straight in.
///
/// The row is pinned left-to-right so the digits keep their order in Urdu,
/// Kashmiri and Sindhi.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.hasError = false,
    this.enabled = true,
    this.autofocus = true,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final bool hasError;
  final bool enabled;
  final bool autofocus;

  /// Fires once the final digit is entered.
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted?.call(widget.controller.text);
    }
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String value = widget.controller.text;

    return Semantics(
      textField: true,
      label: MaterialLocalizations.of(context).searchFieldLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: <Widget>[
            Directionality(
              textDirection: TextDirection.ltr,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  // Boxes share the row evenly, so six of them fit a 320dp
                  // screen without any fixed width to overflow.
                  const double gap = 10;
                  final double boxWidth =
                      (constraints.maxWidth - gap * (widget.length - 1)) /
                          widget.length;

                  return Row(
                    children: <Widget>[
                      for (int i = 0; i < widget.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(width: gap),
                        _OtpBox(
                          width: boxWidth,
                          digit: i < value.length ? value[i] : '',
                          isActive: _focusNode.hasFocus && i == value.length,
                          hasError: widget.hasError,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            Positioned.fill(
              child: Opacity(
                // Invisible but still hit-testable, focusable and autofillable.
                opacity: 0,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.oneTimeCode],
                  showCursor: false,
                  enableInteractiveSelection: false,
                  maxLength: widget.length,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.width,
    required this.digit,
    required this.isActive,
    required this.hasError,
  });

  final double width;
  final String digit;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final bool filled = digit.isNotEmpty;

    final Color border = hasError
        ? scheme.error
        : isActive || filled
            ? (isDark ? AppColors.greenLight : AppColors.green)
            : scheme.outline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: width,
      // Height scales with the type so the digit is never clipped at large
      // system font sizes.
      height: 56 * MediaQuery.textScalerOf(context).scale(14) / 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled
            ? (isDark ? const Color(0xFF1A2A11) : AppColors.greenWash)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: isActive || filled ? 1.8 : 1),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          digit,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
