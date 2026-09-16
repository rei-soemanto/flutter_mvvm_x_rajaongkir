import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/city.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/district.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/province.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/labeled_dropdown.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/section_card.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/domestic/view_models/domestic_view_model.dart';

/// The province, city and district pickers for one end of the shipment.
///
/// Each dropdown only opens once the level above it has been chosen, which is
/// what makes this the step-by-step method. While a lookup is running the
/// pickers are disabled, so an older answer can never land on a newer choice.
class LocationSelectorCard extends StatelessWidget {
  const LocationSelectorCard({
    required this.title,
    required this.icon,
    required this.provinces,
    required this.selection,
    required this.isLoading,
    required this.onProvinceChanged,
    required this.onCityChanged,
    required this.onDistrictChanged,
    super.key,
    this.errorText,
  });

  /// Headline, either Origin or Destination.
  final String title;

  /// Icon shown next to the headline.
  final IconData icon;

  /// Provinces to choose from.
  final List<Province> provinces;

  /// What is chosen so far.
  final LocationSelection selection;

  /// Whether a lookup for this side is running.
  final bool isLoading;

  /// Lookup failure for this side, if any.
  final String? errorText;

  /// Called when a province is chosen.
  final ValueChanged<Province?> onProvinceChanged;

  /// Called when a city is chosen.
  final ValueChanged<City?> onCityChanged;

  /// Called when a district is chosen.
  final ValueChanged<District?> onDistrictChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorText = this.errorText;

    return SectionCard(
      title: title,
      icon: icon,
      children: [
        LabeledDropdown<Province>(
          label: 'Province',
          hint: 'Choose a province',
          value: selection.province,
          items: provinces,
          itemLabel: (province) => province.name,
          enabled: !isLoading,
          onChanged: onProvinceChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        LabeledDropdown<City>(
          label: 'City',
          hint: selection.province == null
              ? 'Choose a province first'
              : 'Choose a city',
          value: selection.city,
          items: selection.cities,
          itemLabel: (city) => city.name,
          enabled: !isLoading && selection.cities.isNotEmpty,
          onChanged: onCityChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        LabeledDropdown<District>(
          label: 'District',
          hint: selection.city == null
              ? 'Choose a city first'
              : 'Choose a district',
          value: selection.district,
          items: selection.districts,
          itemLabel: (district) => district.name,
          enabled: !isLoading && selection.districts.isNotEmpty,
          onChanged: onDistrictChanged,
        ),
        if (isLoading) ...[
          const SizedBox(height: AppSpacing.md),
          const LinearProgressIndicator(),
        ],
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            errorText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
