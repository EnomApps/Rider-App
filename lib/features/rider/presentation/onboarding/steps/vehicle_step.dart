import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../generated/l10n/app_localizations.dart';
import '../../../data/kyc_validators.dart';
import '../../../data/rider_profile.dart';
import '../../widgets/rider_form_field.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_screen.dart';

/// Step 2 — the vehicle and the two numbers that describe it.
///
/// Detail fields 1 and 2 of 11: `vehicle_number` and `rc_number`.
class VehicleStep extends StatefulWidget {
  const VehicleStep({super.key, required this.context});

  final OnboardingStepContext context;

  @override
  State<VehicleStep> createState() => _VehicleStepState();
}

class _VehicleStepState extends State<VehicleStep> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _number = TextEditingController(
    text: widget.context.rider.profile?.vehicleNumber ?? '',
  );
  final TextEditingController _rc = TextEditingController();

  late VehicleType? _type = _initialType;
  String? _typeError;

  VehicleType? get _initialType {
    final VehicleType? current = widget.context.rider.profile?.vehicleType;
    return (current == null || current == VehicleType.unknown) ? null : current;
  }

  @override
  void dispose() {
    _number.dispose();
    _rc.dispose();
    super.dispose();
  }

  String _labelFor(VehicleType type, AppLocalizations l10n) {
    switch (type) {
      case VehicleType.motorcycle:
        return l10n.vehicleMotorcycle;
      case VehicleType.scooter:
        return l10n.vehicleScooter;
      case VehicleType.ev:
        return l10n.vehicleEv;
      case VehicleType.bicycle:
        return l10n.vehicleBicycle;
      case VehicleType.unknown:
        return '';
    }
  }

  IconData _iconFor(VehicleType type) {
    switch (type) {
      case VehicleType.motorcycle:
        return Icons.two_wheeler_rounded;
      case VehicleType.scooter:
        return Icons.moped_rounded;
      case VehicleType.ev:
        return Icons.electric_moped_rounded;
      case VehicleType.bicycle:
        return Icons.pedal_bike_rounded;
      case VehicleType.unknown:
        return Icons.help_outline_rounded;
    }
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();

    final VehicleType? type = _type;
    setState(() => _typeError = type == null ? l10n.fieldRequired : null);

    final bool formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || type == null) return;

    widget.context.onResult(
      await widget.context.rider.saveVehicle(
        vehicleType: type,
        // Normalised on the way out so `TN 01 AB 1234` and `tn01ab1234` are
        // stored identically — an admin comparing this against a photographed
        // RC book should not be tripped by whitespace.
        vehicleNumber: KycValidators.normalisePlate(_number.text),
        rcNumber: _rc.text.trim().isEmpty ? null : _rc.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OnboardingStepContext step = widget.context;
    final bool busy = step.rider.isSaving;

    return OnboardingScaffold(
      stepIndex: step.index,
      stepCount: step.total,
      title: l10n.stepVehicleTitle,
      subtitle: l10n.stepVehicleSubtitle,
      onBack: step.onBack,
      isBusy: busy,
      banner: step.banner,
      primaryLabel: l10n.saveAndContinue,
      onPrimary: _submit,
      formKey: _formKey,
      children: <Widget>[
        RiderChoiceField<VehicleType>(
          label: l10n.vehicleTypeLabel,
          options: VehicleType.selectable,
          labelOf: (VehicleType type) => _labelFor(type, l10n),
          iconOf: _iconFor,
          value: _type,
          enabled: !busy,
          errorText: _typeError,
          onChanged: (VehicleType type) {
            step.onEdited();
            setState(() {
              _type = type;
              _typeError = null;
            });
          },
        ),
        RiderTextField(
          label: l10n.vehicleNumberLabel,
          hint: l10n.vehicleNumberHint,
          controller: _number,
          prefixIcon: Icons.confirmation_number_outlined,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: <TextInputFormatter>[UpperCaseTextFormatter()],
          maxLength: 15,
          enabled: !busy,
          serverError: step.rider.fieldError('vehicle_number'),
          validator: (String? value) =>
              KycValidators.vehicleNumber(value, l10n),
          onChanged: (_) => step.onEdited(),
        ),
        RiderTextField(
          label: l10n.rcNumberLabel,
          controller: _rc,
          prefixIcon: Icons.description_outlined,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: <TextInputFormatter>[UpperCaseTextFormatter()],
          maxLength: 30,
          enabled: !busy,
          serverError: step.rider.fieldError('rc_number'),
          validator: (String? value) => KycValidators.required(value, l10n),
          onChanged: (_) => step.onEdited(),
        ),
      ],
    );
  }
}

/// Uppercases as the rider types.
///
/// Not cosmetic: the API's PAN and IFSC patterns are anchored to uppercase,
/// and `textCapitalization` alone is only a hint to the soft keyboard — a
/// hardware keyboard, a paste, or a keyboard that ignores the hint all get
/// through it.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
