import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/formatters/currency_formatter.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/international/view_models/international_view_model.dart';

/// Chips for the ready-made parcel weights.
class ParcelPresetSelector extends StatelessWidget {
  const ParcelPresetSelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// The preset currently applied.
  final ParcelPreset selected;

  /// Called with the preset the user tapped.
  final ValueChanged<ParcelPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final preset in ParcelPreset.values)
          ChoiceChip(
            label: Text(
              preset == ParcelPreset.custom
                  ? preset.label
                  : '${preset.label} (${formatWeight(preset.grams)})',
            ),
            selected: preset == selected,
            onSelected: (_) => onSelected(preset),
          ),
      ],
    );
  }
}
