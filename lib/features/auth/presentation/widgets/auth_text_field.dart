import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Labelled form field used on the sign-in screen.
///
/// The label sits above the box rather than floating inside it. Floating labels
/// animate into a 12sp slot, which is where Devanagari and Tamil vowel marks
/// start colliding with the border; a static label has room to breathe and
/// wraps cleanly when a translation runs long.
///
/// Content is laid out left-to-right even in Urdu, Kashmiri and Sindhi, because
/// an email address or a phone number is itself LTR.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.prefixIcon,
    this.maxLength,
    this.inputFormatters,
    this.enabled = true,
    this.autofocus = false,
    this.onSubmitted,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final IconData? prefixIcon;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 7),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          enabled: enabled,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          validator: validator,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintMaxLines: 1,
            counterText: '',
            hintTextDirection: TextDirection.ltr,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 21),
            // Errors routinely wrap to two lines once translated.
            errorMaxLines: 3,
          ),
        ),
      ],
    );
  }
}
