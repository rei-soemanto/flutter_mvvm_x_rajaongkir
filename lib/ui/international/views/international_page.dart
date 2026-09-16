import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/country.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/courier.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/domestic_destination.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/formatters/currency_formatter.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/formatters/error_message.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/card_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/cost_details.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/courier_selector.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/responsive_body.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/section_card.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/status_views.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/weight_field.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/international/view_models/international_view_model.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/international/widgets/destination_search_field.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/international/widgets/parcel_preset_selector.dart';
import 'package:provider/provider.dart';

/// Page two: sending a parcel abroad, built on the direct search method.
///
/// The origin comes from Search Domestic Destination and the destination from
/// Search International Destination, which is what Calculate International Cost
/// needs. Results can be ordered by price or by speed, and tapping one opens a
/// dialog with the full API response.
class InternationalPage extends StatefulWidget {
  const InternationalPage({super.key});

  @override
  State<InternationalPage> createState() => _InternationalPageState();
}

class _InternationalPageState extends State<InternationalPage> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: '${context.read<InternationalViewModel>().weightGrams}',
    );
  }

  @override
  void dispose() {
    _originController.dispose();
    _countryController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InternationalViewModel>();
    final origin = viewModel.origin;
    final country = viewModel.country;

    // Keep the weight box in step when a preset changes it.
    final weightText = '${viewModel.weightGrams}';
    if (viewModel.preset != ParcelPreset.custom &&
        _weightController.text != weightText) {
      _weightController.value = TextEditingValue(
        text: weightText,
        selection: TextSelection.collapsed(offset: weightText.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('International'),
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
                'Direct search: type a place and a country.',
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
            SectionCard(
              title: 'Send from',
              icon: Icons.outbox_outlined,
              subtitle: 'Search a city, district or postal code in Indonesia.',
              children: [
                if (origin == null)
                  DestinationSearchField<DomesticDestination>(
                    label: 'Origin',
                    hint: 'For example Sleman or 55581',
                    controller: _originController,
                    onQueryChanged: viewModel.onOriginQueryChanged,
                    isSearching: viewModel.isSearchingOrigin,
                    errorText: viewModel.originError,
                    emptyHint: 'No place matched that search.',
                    results: viewModel.originResults,
                    itemTitle: (item) => item.shortLabel,
                    itemSubtitle: (item) => item.label,
                    onSelected: viewModel.selectOrigin,
                  )
                else
                  SelectedDestinationTile(
                    icon: Icons.location_on_outlined,
                    title: origin.shortLabel,
                    subtitle: origin.label,
                    onChange: () {
                      _originController.clear();
                      viewModel.clearOrigin();
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              title: 'Send to',
              icon: Icons.public,
              subtitle: 'Search the destination country.',
              children: [
                if (country == null)
                  DestinationSearchField<Country>(
                    label: 'Country',
                    hint: 'For example Malaysia',
                    controller: _countryController,
                    onQueryChanged: viewModel.onCountryQueryChanged,
                    isSearching: viewModel.isSearchingCountry,
                    errorText: viewModel.countryError,
                    emptyHint: 'No country matched that search.',
                    results: viewModel.countryResults,
                    itemTitle: (item) => item.name,
                    onSelected: viewModel.selectCountry,
                  )
                else
                  SelectedDestinationTile(
                    icon: Icons.flag_outlined,
                    title: country.name,
                    subtitle: 'Country id ${country.id}',
                    onChange: () {
                      _countryController.clear();
                      viewModel.clearCountry();
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              title: 'Parcel',
              icon: Icons.inventory_2_outlined,
              children: [
                ParcelPresetSelector(
                  selected: viewModel.preset,
                  onSelected: viewModel.selectPreset,
                ),
                const SizedBox(height: AppSpacing.lg),
                WeightField(
                  controller: _weightController,
                  errorText: viewModel.weightError,
                  onChanged: viewModel.setWeight,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Couriers', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                CourierSelector(
                  couriers: Courier.international,
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

  final InternationalViewModel viewModel;

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
                : const Icon(Icons.flight_takeoff),
            label: Text(isRunning ? 'Calculating' : 'Calculate cost'),
          ),
        );
      },
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.viewModel});

  final InternationalViewModel viewModel;

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
            icon: Icons.public,
            title: 'No quote yet',
            message: 'Pick where the parcel starts and where it is going.',
          );
        }

        final results = viewModel.results;
        if (results.isEmpty) {
          return const EmptyView(
            icon: Icons.search_off,
            title: 'No services found',
            message: 'No courier ships this parcel to that country.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${results.length} services',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                SegmentedButton<CostSort>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: CostSort.cheapest,
                      label: Text('Cheapest'),
                    ),
                    ButtonSegment(
                      value: CostSort.fastest,
                      label: Text('Fastest'),
                    ),
                  ],
                  selected: {viewModel.sort},
                  onSelectionChanged: (selection) =>
                      viewModel.setSort(selection.first),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Weight ${formatWeight(viewModel.weightGrams)}. Tap a card for '
              'the full API response.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final cost in results) ...[
              CardCost(
                cost: cost,
                badge: viewModel.badgeFor(cost),
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
