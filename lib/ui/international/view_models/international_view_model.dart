import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_mvvm_x_rajaongkir/config/app_config.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/repositories/history_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/repositories/international_shipping_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/api_exception.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/country.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/courier.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/domestic_destination.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_history_entry.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/formatters/error_message.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/command.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/debouncer.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/result.dart';

/// Ready-made weights so a quote takes two taps instead of typing grams.
enum ParcelPreset {
  /// Papers and contracts.
  document(label: 'Document', grams: 500),

  /// Up to one kilogram.
  small(label: 'Small parcel', grams: 1000),

  /// Up to three kilograms.
  medium(label: 'Medium parcel', grams: 3000),

  /// Up to five kilograms.
  large(label: 'Large parcel', grams: 5000),

  /// Whatever the user types.
  custom(label: 'Custom', grams: 0);

  const ParcelPreset({required this.label, required this.grams});

  /// Chip label.
  final String label;

  /// Weight this preset stands for, in grams. Zero for [custom].
  final int grams;
}

/// How the result list is ordered.
enum CostSort {
  /// Lowest price first.
  cheapest,

  /// Shortest delivery estimate first.
  fastest,
}

/// Drives the international page, which uses the direct search method.
///
/// Instead of drilling through province, city and district, the user types a
/// place and a country and picks from the answers. Both searches are debounced
/// and only the newest answer is applied, which keeps the daily API quota low
/// and stops an older answer from overwriting a newer one.
class InternationalViewModel extends ChangeNotifier {
  InternationalViewModel({
    required this._repository,
    required this._historyRepository,
    Duration debounce = AppConfig.searchDebounce,
  }) : _originDebouncer = Debouncer(duration: debounce),
       _countryDebouncer = Debouncer(duration: debounce) {
    calculate = Command0<void>(_calculate);
  }

  final InternationalShippingRepository _repository;
  final HistoryRepository _historyRepository;
  final Debouncer _originDebouncer;
  final Debouncer _countryDebouncer;

  /// Runs the Calculate International Cost request.
  late final Command0<void> calculate;

  List<DomesticDestination> _originResults = const [];
  bool _originSearching = false;
  String? _originError;
  int _originToken = 0;
  DomesticDestination? _origin;

  List<Country> _countryResults = const [];
  bool _countrySearching = false;
  String? _countryError;
  int _countryToken = 0;
  Country? _country;

  ParcelPreset _preset = ParcelPreset.small;
  int _weightGrams = 1000;
  String? _weightError;
  final Set<String> _courierCodes = {...Courier.defaultInternationalCodes};
  CostSort _sort = CostSort.cheapest;
  List<InternationalShippingCost> _results = const [];
  bool _hasCalculated = false;

  /// Places matching the origin search.
  List<DomesticDestination> get originResults =>
      List.unmodifiable(_originResults);

  /// Whether an origin search is running.
  bool get isSearchingOrigin => _originSearching;

  /// Origin search failure, if any.
  String? get originError => _originError;

  /// The chosen origin.
  DomesticDestination? get origin => _origin;

  /// Countries matching the destination search.
  List<Country> get countryResults => List.unmodifiable(_countryResults);

  /// Whether a country search is running.
  bool get isSearchingCountry => _countrySearching;

  /// Country search failure, if any.
  String? get countryError => _countryError;

  /// The chosen destination country.
  Country? get country => _country;

  /// The selected parcel preset.
  ParcelPreset get preset => _preset;

  /// Parcel weight in grams.
  int get weightGrams => _weightGrams;

  /// Why the typed weight cannot be used, or null when it is fine.
  String? get weightError => _weightError;

  /// Courier codes the user ticked.
  Set<String> get courierCodes => Set.unmodifiable(_courierCodes);

  /// Current ordering of the results.
  CostSort get sort => _sort;

  /// Whether a calculation has finished at least once.
  bool get hasCalculated => _hasCalculated;

  /// Results in the order the user asked for.
  List<InternationalShippingCost> get results {
    final sorted = [..._results];
    switch (_sort) {
      case CostSort.cheapest:
        sorted.sort((a, b) => a.cost.compareTo(b.cost));
      case CostSort.fastest:
        sorted.sort(_bySpeedThenPrice);
    }
    return List.unmodifiable(sorted);
  }

  /// The lowest priced result.
  InternationalShippingCost? get cheapest => _results.isEmpty
      ? null
      : _results.reduce((a, b) => a.cost <= b.cost ? a : b);

  /// The result with the shortest estimate, ignoring couriers that gave none.
  InternationalShippingCost? get fastest {
    final estimated = _results
        .where((cost) => cost.estimatedDays != null)
        .toList();
    if (estimated.isEmpty) {
      return null;
    }
    return estimated.reduce(
      (a, b) => (a.estimatedDays ?? 0) <= (b.estimatedDays ?? 0) ? a : b,
    );
  }

  /// The highlight to show on [cost], if it earned one.
  String? badgeFor(InternationalShippingCost cost) {
    final isCheapest = identical(cost, cheapest);
    final isFastest = identical(cost, fastest);
    if (isCheapest && isFastest) {
      return 'Best price and fastest';
    }
    if (isCheapest) {
      return 'Best price';
    }
    if (isFastest) {
      return 'Fastest';
    }
    return null;
  }

  /// Whether the form is complete enough to calculate.
  bool get canCalculate =>
      _origin != null &&
      _country != null &&
      _courierCodes.isNotEmpty &&
      _weightError == null &&
      _weightGrams > 0;

  /// Called on every keystroke in the origin field.
  void onOriginQueryChanged(String query) {
    _originDebouncer.run(() => unawaited(_searchOrigins(query)));
  }

  /// Called on every keystroke in the country field.
  void onCountryQueryChanged(String query) {
    _countryDebouncer.run(() => unawaited(_searchCountries(query)));
  }

  /// Chooses the origin and hides the suggestions.
  void selectOrigin(DomesticDestination destination) {
    _origin = destination;
    _originResults = const [];
    _originError = null;
    notifyListeners();
  }

  /// Clears the origin so it can be searched again.
  void clearOrigin() {
    _origin = null;
    _originResults = const [];
    notifyListeners();
  }

  /// Chooses the destination country and hides the suggestions.
  void selectCountry(Country country) {
    _country = country;
    _countryResults = const [];
    _countryError = null;
    notifyListeners();
  }

  /// Clears the country so it can be searched again.
  void clearCountry() {
    _country = null;
    _countryResults = const [];
    notifyListeners();
  }

  /// Applies a parcel preset. [ParcelPreset.custom] keeps the typed weight.
  void selectPreset(ParcelPreset preset) {
    _preset = preset;
    if (preset != ParcelPreset.custom) {
      _weightGrams = preset.grams;
      _weightError = null;
    }
    notifyListeners();
  }

  /// Validates and stores a typed weight, switching to the custom preset.
  void setWeight(String value) {
    _preset = ParcelPreset.custom;
    final grams = int.tryParse(value.trim());
    if (grams == null || grams <= 0) {
      _weightError = 'Enter the weight in grams, for example 1000.';
    } else if (grams > 100000) {
      _weightError = 'That is over 100 kg. Enter a smaller weight.';
    } else {
      _weightError = null;
      _weightGrams = grams;
    }
    notifyListeners();
  }

  /// Ticks or unticks a courier.
  void toggleCourier(String code) {
    if (!_courierCodes.remove(code)) {
      _courierCodes.add(code);
    }
    notifyListeners();
  }

  /// Changes how the results are ordered.
  void setSort(CostSort sort) {
    if (sort == _sort) {
      return;
    }
    _sort = sort;
    notifyListeners();
  }

  @override
  void dispose() {
    _originDebouncer.cancel();
    _countryDebouncer.cancel();
    super.dispose();
  }

  Future<void> _searchOrigins(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < AppConfig.minSearchLength) {
      _originResults = const [];
      _originSearching = false;
      _originError = null;
      notifyListeners();
      return;
    }

    final token = ++_originToken;
    _originSearching = true;
    _originError = null;
    notifyListeners();

    final result = await _repository.searchOrigins(trimmed);
    if (token != _originToken) {
      // A newer search started while this one was in flight.
      return;
    }

    _originSearching = false;
    switch (result) {
      case Ok<List<DomesticDestination>>(:final value):
        _originResults = value;
      case Failure<List<DomesticDestination>>(:final error):
        _originResults = const [];
        _originError = describeError(error);
    }
    notifyListeners();
  }

  Future<void> _searchCountries(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < AppConfig.minSearchLength) {
      _countryResults = const [];
      _countrySearching = false;
      _countryError = null;
      notifyListeners();
      return;
    }

    final token = ++_countryToken;
    _countrySearching = true;
    _countryError = null;
    notifyListeners();

    final result = await _repository.searchCountries(trimmed);
    if (token != _countryToken) {
      return;
    }

    _countrySearching = false;
    switch (result) {
      case Ok<List<Country>>(:final value):
        _countryResults = value;
      case Failure<List<Country>>(:final error):
        _countryResults = const [];
        _countryError = describeError(error);
    }
    notifyListeners();
  }

  Future<Result<void>> _calculate() async {
    final origin = _origin;
    final country = _country;
    if (origin == null || country == null) {
      return Failure<void>(
        const ApiException('Choose an origin and a destination country first'),
      );
    }

    final result = await _repository.calculateCost(
      originId: origin.id,
      countryId: country.id,
      weightGrams: _weightGrams,
      courierCodes: _courierCodes.toList(),
    );

    _hasCalculated = true;
    switch (result) {
      case Ok<List<InternationalShippingCost>>(:final value):
        _results = value;
        notifyListeners();
        await _saveToHistory(origin, country, value);
        return const Ok<void>(null);
      case Failure<List<InternationalShippingCost>>(:final error):
        _results = const [];
        notifyListeners();
        return Failure<void>(error);
    }
  }

  Future<void> _saveToHistory(
    DomesticDestination origin,
    Country country,
    List<InternationalShippingCost> results,
  ) async {
    final entry = InternationalHistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      originLabel: origin.shortLabel,
      destinationLabel: country.name,
      weightGrams: _weightGrams,
      courierCodes: _courierCodes.toList(),
      results: results,
    );

    final saved = await _historyRepository.add(entry);
    if (saved case Failure<void>(:final error)) {
      debugPrint('InternationalViewModel: could not save history: $error');
    }
  }

  int _bySpeedThenPrice(
    InternationalShippingCost a,
    InternationalShippingCost b,
  ) {
    final aDays = a.estimatedDays;
    final bDays = b.estimatedDays;
    if (aDays == null && bDays == null) {
      return a.cost.compareTo(b.cost);
    }
    // Couriers without an estimate go last.
    if (aDays == null) {
      return 1;
    }
    if (bDays == null) {
      return -1;
    }
    final bySpeed = aDays.compareTo(bDays);
    return bySpeed != 0 ? bySpeed : a.cost.compareTo(b.cost);
  }
}
