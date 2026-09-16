import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/courier.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';

/// Multi-select chips for the couriers to ask the API about.
///
/// The selected codes are joined with `:` before they are sent, so asking about
/// several couriers still costs a single request.
class CourierSelector extends StatelessWidget {
  const CourierSelector({
    required this.couriers,
    required this.selectedCodes,
    required this.onToggle,
    super.key,
  });

  /// Couriers offered for the current page.
  final List<Courier> couriers;

  /// Codes currently selected.
  final Set<String> selectedCodes;

  /// Called with the code of the chip the user tapped.
  final void Function(String code) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final courier in couriers)
          FilterChip(
            label: Text(courier.label),
            selected: selectedCodes.contains(courier.code),
            onSelected: (_) => onToggle(courier.code),
          ),
      ],
    );
  }
}
