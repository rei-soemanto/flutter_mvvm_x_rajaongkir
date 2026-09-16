import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/cost_attributes.dart';

/// Dialog listing every attribute of a Calculate International Cost result.
///
/// The international page uses a dialog where the domestic page uses a bottom
/// sheet, so both pop-up styles appear in the app. It also shows the exchange
/// rate fields, which only some couriers send.
class InternationalCostDialog extends StatelessWidget {
  const InternationalCostDialog({required this.cost, super.key});

  /// The result whose attributes are listed.
  final InternationalShippingCost cost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(cost.name),
      content: SizedBox(
        width: AppSpacing.maxContentWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service ${cost.service}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(),
              Text('API response', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              ...buildCostAttributeRows(cost),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
