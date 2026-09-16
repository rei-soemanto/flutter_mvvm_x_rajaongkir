import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Numeric input for the parcel weight in grams.
class WeightField extends StatelessWidget {
  const WeightField({
    required this.controller,
    required this.onChanged,
    super.key,
    this.errorText,
    this.helperText = 'The API charges by gram, so 1 kg is 1000.',
  });

  /// Controls the text shown in the field.
  final TextEditingController controller;

  /// Called with the raw text whenever it changes.
  final void Function(String value) onChanged;

  /// Validation message, when the current value cannot be used.
  final String? errorText;

  /// Hint under the field.
  final String helperText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: 'Weight',
        suffixText: 'grams',
        helperText: helperText,
        errorText: errorText,
      ),
    );
  }
}
