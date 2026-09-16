import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/courier.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/formatters/error_message.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/card_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/cost_details.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/courier_selector.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/responsive_body.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/section_card.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/status_views.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/weight_field.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/domestic/view_models/domestic_view_model.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/domestic/widgets/location_selector_card.dart';
import 'package:provider/provider.dart';

/// Page one: a domestic quote built with the step-by-step method.
///
/// Province, city and district are chosen for both ends of the shipment, then
/// District Calculate Cost returns one card per courier service. Tapping a card
/// opens the bottom sheet with the full API response.
class DomesticPage extends StatefulWidget {
  const DomesticPage({super.key});

  @override
  State<DomesticPage> createState() => _DomesticPageState();
}

class _DomesticPageState extends State<DomesticPage> {
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: '${context.read<DomesticViewModel>().weightGrams}',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DomesticViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Domestic'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(AppSpacing.xlg),
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Step by step: province, city, then district.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            LocationSelectorCard(
              title: 'Origin',
              icon: Icons.outbox_outlined,
              provinces: viewModel.provinces,
              selection: viewModel.origin,
              isLoading: viewModel.isSideLoading(LocationSide.origin),
              errorText: viewModel.sideError(LocationSide.origin),
              onProvinceChanged: (province) =>
                  viewModel.selectProvince(LocationSide.origin, province),
              onCityChanged: (city) =>
                  viewModel.selectCity(LocationSide.origin, city),
              onDistrictChanged: (district) =>
                  viewModel.selectDistrict(LocationSide.origin, district),
            ),
            const SizedBox(height: AppSpacing.lg),
            LocationSelectorCard(
              title: 'Destination',
              icon: Icons.inbox_outlined,
              provinces: viewModel.provinces,
              selection: viewModel.destination,
              isLoading: viewModel.isSideLoading(LocationSide.destination),
              errorText: viewModel.sideError(LocationSide.destination),
              onProvinceChanged: (province) =>
                  viewModel.selectProvince(LocationSide.destination, province),
              onCityChanged: (city) =>
                  viewModel.selectCity(LocationSide.destination, city),
              onDistrictChanged: (district) =>
                  viewModel.selectDistrict(LocationSide.destination, district),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              title: 'Parcel',
              icon: Icons.inventory_2_outlined,
              children: [
                WeightField(
                  controller: _weightController,
                  errorText: viewModel.weightError,
                  onChanged: viewModel.setWeight,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Couriers', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                CourierSelector(
                  couriers: Courier.domestic,
                  selectedCodes: viewModel.courierCodes,
                  onToggle: viewModel.toggleCourier,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _CalculateButton(viewModel: viewModel),
            const SizedBox(height: AppSpacing.lg),
            _Results(viewModel: viewModel),
          ],
        ),
      ),
    );
  }
}

class _CalculateButton extends StatelessWidget {
  const _CalculateButton({required this.viewModel});

  final DomesticViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel.calculate,
      builder: (context, _) {
        final isRunning = viewModel.calculate.running;
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: viewModel.canCalculate && !isRunning
                ? viewModel.calculate.execute
                : null,
            icon: isRunning
                ? const SizedBox(
                    width: AppSpacing.lg,
                    height: AppSpacing.lg,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.calculate_outlined),
            label: Text(isRunning ? 'Calculating' : 'Calculate cost'),
          ),
        );
      },
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.viewModel});

  final DomesticViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: viewModel.calculate,
      builder: (context, _) {
        final command = viewModel.calculate;

        if (command.running) {
          return const LoadingView(message: 'Asking the couriers for prices.');
        }
        if (command.failed) {
          return ErrorView(
            message: describeError(command.error),
            onRetry: viewModel.canCalculate ? command.execute : null,
          );
        }
        if (!viewModel.hasCalculated) {
          return const EmptyView(
            icon: Icons.local_shipping_outlined,
            title: 'No quote yet',
            message:
                'Choose an origin and a destination district, then calculate.',
          );
        }

        final costs = viewModel.costs;
        if (costs.isEmpty) {
          return const EmptyView(
            icon: Icons.search_off,
            title: 'No services found',
            message: 'Those couriers do not serve this route. Try others.',
          );
        }

        final cheapest = viewModel.cheapest;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${costs.length} services found',
              style: theme.textTheme.titleMedium,
            ),
            Text(
              'Tap a card to see the full API response.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final cost in costs) ...[
              CardCost(
                cost: cost,
                badge: identical(cost, cheapest) ? 'Best price' : null,
                onTap: () => showShippingCostDetails(context, cost),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}
