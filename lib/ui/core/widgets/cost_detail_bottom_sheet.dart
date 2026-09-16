import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/cost_attributes.dart';

/// Bottom sheet listing every attribute of a District Calculate Cost result.
///
/// This is the pop-up the assignment asks for: it opens when a [CardCost] on
/// the domestic page is tapped and shows each key-value pair of the response,
/// including `description`.
class CostDetailBottomSheet extends StatelessWidget {
  const CostDetailBottomSheet({required this.cost, super.key});

  /// The result whose attributes are listed.
  final DomesticShippingCost cost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cost.name, style: theme.textTheme.titleLarge),
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
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
