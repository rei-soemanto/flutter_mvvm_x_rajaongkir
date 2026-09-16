import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/courier.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_history_entry.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/formatters/currency_formatter.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/formatters/date_formatter.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/formatters/error_message.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/card_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/cost_details.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/responsive_body.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/section_card.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/status_views.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/history/view_models/history_detail_view_model.dart';
import 'package:provider/provider.dart';

/// Reopens one saved calculation, with the same cards and pop-ups the original
/// page used.
class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HistoryDetailViewModel>();
    final entry = viewModel.entry;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved calculation')),
      body: ResponsiveBody(
        child: ListenableBuilder(
          listenable: viewModel.load,
          builder: (context, _) {
            if (viewModel.load.running) {
              return const LoadingView();
            }
            if (entry == null) {
              return ErrorView(
                message: viewModel.load.failed
                    ? describeError(viewModel.load.error)
                    : 'That saved calculation could not be found.',
                onRetry: viewModel.load.execute,
              );
            }

            return _EntryDetails(entry: entry);
          },
        ),
      ),
    );
  }
}

class _EntryDetails extends StatelessWidget {
  const _EntryDetails({required this.entry});

  final ShippingHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = entry.results;
    final cheapest = entry.cheapest;
    final isDomestic = entry.type == ShipmentType.domestic;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SectionCard(
          title: isDomestic ? 'Domestic shipment' : 'International shipment',
          icon: isDomestic ? Icons.local_shipping_outlined : Icons.public,
          subtitle: formatHistoryDate(entry.createdAt),
          children: [
            _DetailRow(
              label: 'From',
              value: entry.originLabel.isEmpty ? 'Unknown' : entry.originLabel,
            ),
            _DetailRow(
              label: 'To',
              value: entry.destinationLabel.isEmpty
                  ? 'Unknown'
                  : entry.destinationLabel,
            ),
            _DetailRow(label: 'Weight', value: formatWeight(entry.weightGrams)),
            _DetailRow(
              label: 'Couriers',
              value: entry.courierCodes.map(Courier.labelFor).join(', '),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (results.isEmpty)
          const EmptyView(
            icon: Icons.search_off,
            title: 'No services',
            message: 'This calculation returned no courier services.',
          )
        else ...[
          Text(
            '${results.length} services',
            style: theme.textTheme.titleMedium,
          ),
          Text(
            'Tap a card to see the full API response.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final cost in results) ...[
            CardCost(
              cost: cost,
              badge: identical(cost, cheapest) ? 'Best price' : null,
              onTap: () => showShippingCostDetails(context, cost),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: theme.textTheme.titleSmall),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 7,
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
