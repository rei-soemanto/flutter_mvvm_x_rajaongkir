import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/courier.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_history_entry.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/formatters/currency_formatter.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/formatters/date_formatter.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_radius.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';

/// One saved calculation in the history list.
class HistoryEntryTile extends StatelessWidget {
  const HistoryEntryTile({required this.entry, required this.onTap, super.key});

  /// The saved calculation.
  final ShippingHistoryEntry entry;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cheapest = entry.cheapest;
    final isDomestic = entry.type == ShipmentType.domestic;
    final couriers = entry.courierCodes.map(Courier.labelFor).join(', ');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isDomestic
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.tertiaryContainer,
                    child: Icon(
                      isDomestic ? Icons.local_shipping_outlined : Icons.public,
                      color: isDomestic
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.originLabel.isEmpty
                              ? 'Unknown origin'
                              : entry.originLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              size: AppSpacing.md,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Expanded(
                              child: Text(
                                entry.destinationLabel.isEmpty
                                    ? 'Unknown destination'
                                    : entry.destinationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${formatWeight(entry.weightGrams)} via $couriers',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatHistoryDate(entry.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (cheapest != null)
                    Text(
                      'from ${_priceOf(cheapest)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  else
                    Text(
                      'No services',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _priceOf(ShippingCost cost) => switch (cost) {
    InternationalShippingCost(:final currency) => formatMoney(
      cost.cost,
      currency,
    ),
    DomesticShippingCost() => formatRupiah(cost.cost),
  };
}
