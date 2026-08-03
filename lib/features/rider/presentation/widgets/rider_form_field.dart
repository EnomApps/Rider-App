import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../generated/l10n/app_localizations.dart';

/// Text field for the onboarding wizard.
///
/// Shares `AuthTextField`'s layout — static label above the box, LTR content —
/// for the same reasons: a floating label crushes Devanagari and Tamil vowel
/// marks into a 12sp slot, and a licence or account number is itself
/// left-to-right in every language.
///
/// The one thing it adds is [serverError]. A 422 from `PATCH /v1/rider/kyc/details`
/// names the field it rejected, and that error has to land on the right box
/// rather than in a banner at the bottom of a five-field form.
class RiderTextField extends StatelessWidget {
  const RiderTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.validator,
    this.serverError,
    this.enabled = true,
    this.prefixIcon,
    this.helper,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final FormFieldValidator<String>? validator;

  /// Error the API recorded against this field on the last 422. Shown until
  /// the rider edits the box, at which point the form clears it.
  final String? serverError;

  final bool enabled;
  final IconData? prefixIcon;
  final String? helper;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
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
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            onChanged: onChanged,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textDirection: TextDirection.ltr,
            // The server's verdict outranks the local one: it saw the value
            // the API actually stores, and a client rule can only ever be an
            // approximation of it.
            validator: (String? value) =>
                serverError ?? validator?.call(value),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintMaxLines: 1,
              counterText: '',
              hintTextDirection: TextDirection.ltr,
              helperText: helper,
              helperMaxLines: 2,
              prefixIcon:
                  prefixIcon == null ? null : Icon(prefixIcon, size: 21),
              errorMaxLines: 3,
              errorText: serverError,
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only field that opens a date picker.
///
/// A `TextField` with a picker rather than a bare button so it sits in the
/// same column rhythm as the text fields around it and carries the same label,
/// error and helper affordances.
class RiderDateField extends StatelessWidget {
  const RiderDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.serverError,
    this.errorText,
    this.enabled = true,
    this.helper,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? serverError;

  /// Locally-derived error — "this date has already passed", say. Shown only
  /// when there is no [serverError] to show instead.
  final String? errorText;

  final bool enabled;
  final String? helper;

  Future<void> _pick(BuildContext context) async {
    final DateTime initial = value ?? _clamp(DateTime.now());
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onChanged(picked);
  }

  /// `showDatePicker` asserts when the initial date falls outside the range,
  /// which is exactly what happens on the date-of-birth field: today is later
  /// than the newest allowed birth date.
  DateTime _clamp(DateTime date) {
    if (date.isBefore(firstDate)) return firstDate;
    if (date.isAfter(lastDate)) return lastDate;
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? error = serverError ?? errorText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
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
          InkWell(
            onTap: enabled ? () => _pick(context) : null,
            borderRadius: BorderRadius.circular(16),
            child: InputDecorator(
              isEmpty: value == null,
              decoration: InputDecoration(
                helperText: helper,
                helperMaxLines: 2,
                errorText: error,
                errorMaxLines: 3,
                prefixIcon: const Icon(Icons.event_outlined, size: 21),
                suffixIcon: const Icon(Icons.expand_more_rounded, size: 22),
              ),
              child: Text(
                value == null ? l10n.selectDate : formatDate(value!),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: value == null
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `DD MMM YYYY` with a Latin-digit month abbreviation.
///
/// Deliberately not `intl`'s locale-aware formatter: this string is read back
/// against a printed licence or an RC book, both of which carry the date in
/// exactly this form, and a Tamil or Devanagari rendering of it would be
/// harder to check rather than easier.
String formatDate(DateTime date) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final String day = date.day.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]} ${date.year}';
}

/// Single-choice picker rendered as a wrap of pills.
///
/// A `DropdownButton` would be the obvious choice, but four options fit on one
/// or two rows, and a pill row is one tap instead of two — which matters on a
/// form the rider fills in once, standing next to their bike.
class RiderChoiceField<T> extends StatelessWidget {
  const RiderChoiceField({
    super.key,
    required this.label,
    required this.options,
    required this.labelOf,
    required this.value,
    required this.onChanged,
    this.iconOf,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final List<T> options;
  final String Function(T) labelOf;
  final IconData Function(T)? iconOf;
  final T? value;
  final ValueChanged<T> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 9),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final T option in options)
                _ChoicePill(
                  label: labelOf(option),
                  icon: iconOf?.call(option),
                  selected: option == value,
                  enabled: enabled,
                  onTap: () => onChanged(option),
                ),
            ],
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, top: 8),
              child: Text(
                errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? theme.colorScheme.error
                      : theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = theme.colorScheme.primary;
    final BorderRadius radius = BorderRadius.circular(999);

    return Material(
      color: selected
          ? accent.withValues(alpha: theme.brightness == Brightness.dark
              ? 0.18
              : 0.10)
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: radius,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? accent : theme.colorScheme.outline,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(
                    icon,
                    size: 19,
                    color: selected
                        ? accent
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected ? accent : theme.colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
