import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';

/// One attribute of an API response, shown as a key-value pair.
///
/// The raw JSON key is printed under the label so it is obvious which part of
/// the RajaOngkir payload each line comes from.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    required this.label,
    required this.apiKey,
    required this.value,
    super.key,
  });

  /// Human readable name of the attribute, for example `Description`.
  final String label;

  /// Raw key as the API sends it, for example `description`.
  final String apiKey;

  /// Formatted value.
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleSmall),
                Text(
                  apiKey,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
