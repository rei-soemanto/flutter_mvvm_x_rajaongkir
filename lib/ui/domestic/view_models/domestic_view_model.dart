import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/repositories/history_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/repositories/region_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/repositories/shipping_cost_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/api_exception.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/city.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/courier.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/district.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/province.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_history_entry.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/formatters/error_message.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/command.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/result.dart';

/// Which end of the shipment a location belongs to.
enum LocationSide {
  /// Where the parcel is sent from.
  origin,

  /// Where the parcel is sent to.
  destination,
}

/// The province, city and district chosen for one side, with the lists the user
/// picks from.
class LocationSelection {
  const LocationSelection({
    this.province,
    this.city,
    this.district,
    this.cities = const [],
    this.districts = const [],
  });

  /// Chosen province.
  final Province? province;

  /// Chosen city.
  final City? city;

  /// Chosen district, which is what the cost endpoint needs.
  final District? district;

  /// Cities of the chosen province.
  final List<City> cities;

  /// Districts of the chosen city.
  final List<District> districts;

  /// Whether a district has been chosen, so a cost can be calculated.
  bool get isComplete => district != null;

  /// One line naming the place, used in the history list.
  String get label => [
    district?.name,
    city?.name,
    province?.name,
  ].whereType<String>().join(', ');

  /// Starts a fresh selection for [province], dropping city and district.
  LocationSelection withProvince(Province province) =>
      LocationSelection(province: province);

  /// Stores the cities of the chosen province.
  LocationSelection withCities(List<City> cities) =>
      LocationSelection(province: province, cities: cities);

  /// Chooses [city], dropping any district already chosen.
  LocationSelection withCity(City city) =>
      LocationSelection(province: province, cities: cities, city: city);

  /// Stores the districts of the chosen city.
  LocationSelection withDistricts(List<District> districts) =>
      LocationSelection(
        province: province,
        cities: cities,
        city: city,
        districts: districts,
      );

  /// Chooses [district].
  LocationSelection withDistrict(District district) => LocationSelection(
    province: province,
    cities: cities,
    city: city,
    districts: districts,
    district: district,
  );
}

/// Drives the domestic page, which follows the step-by-step method:
/// province, then city, then district, then District Calculate Cost.
class DomesticViewModel extends ChangeNotifier {
  DomesticViewModel({
    required this._regionRepository,
    required this._shippingCostRepository,
    required this._historyRepository,
  }) {
    loadProvinces = Command0<void>(_loadProvinces);
    calculate = Command0<void>(_calculate);
    unawaited(loadProvinces.execute());
  }

  final RegionRepository _regionRepository;
  final ShippingCostRepository _shippingCostRepository;
  final HistoryRepository _historyRepository;

  /// Loads the province list. Runs once when the page is created.
  late final Command0<void> loadProvinces;

  /// Runs the District Calculate Cost request.
  ///
  /// A command refuses to start while it is already running, which is exactly
  /// what a calculate button needs.
  late final Command0<void> calculate;

  List<Province> _provinces = const [];
  LocationSelection _origin = const LocationSelection();
  LocationSelection _destination = const LocationSelection();
  final Map<LocationSide, bool> _loading = {
    LocationSide.origin: false,
    LocationSide.destination: false,
  };
  final Map<LocationSide, String?> _errors = {
    LocationSide.origin: null,
    LocationSide.destination: null,
  };
  final Map<LocationSide, int> _requestTokens = {
    LocationSide.origin: 0,
    LocationSide.destination: 0,
  };
  final Set<String> _courierCodes = {...Courier.defaultDomesticCodes};
  int _weightGrams = 1000;
  String? _weightError;
  List<DomesticShippingCost> _costs = const [];
  bool _hasCalculated = false;

  /// Every province, for both dropdowns.
  List<Province> get provinces => List.unmodifiable(_provinces);

  /// The origin selection.
  LocationSelection get origin => _origin;

  /// The destination selection.
  LocationSelection get destination => _destination;

  /// Courier codes the user ticked.
  Set<String> get courierCodes => Set.unmodifiable(_courierCodes);

  /// Parcel weight in grams.
  int get weightGrams => _weightGrams;

  /// Why the typed weight cannot be used, or null when it is fine.
  String? get weightError => _weightError;

  /// Results of the last calculation, cheapest first.
  List<DomesticShippingCost> get costs => List.unmodifiable(_costs);

  /// Whether a calculation has finished at least once, so the page knows
  /// whether an empty list means "no results" or "nothing asked yet".
  bool get hasCalculated => _hasCalculated;

  /// The cheapest result, highlighted in the list.
  DomesticShippingCost? get cheapest =>
      _costs.isEmpty ? null : _costs.reduce((a, b) => a.cost <= b.cost ? a : b);

  /// Whether one side is still loading its cities or districts.
  bool isSideLoading(LocationSide side) => _loading[side] ?? false;

  /// The lookup error for one side, if any.
  String? sideError(LocationSide side) => _errors[side];

  /// The selection of one side.
  LocationSelection selectionOf(LocationSide side) =>
      side == LocationSide.origin ? _origin : _destination;

  /// Whether the form is complete enough to calculate.
  bool get canCalculate =>
      _origin.isComplete &&
      _destination.isComplete &&
      _courierCodes.isNotEmpty &&
      _weightError == null &&
      _weightGrams > 0;

  /// Chooses a province and loads its cities.
  Future<void> selectProvince(LocationSide side, Province? province) async {
    if (province == null || selectionOf(side).province == province) {
      return;
    }
    _setSelection(side, selectionOf(side).withProvince(province));
    await _loadCities(side, province);
  }

  /// Chooses a city and loads its districts.
  Future<void> selectCity(LocationSide side, City? city) async {
    if (city == null || selectionOf(side).city == city) {
      return;
    }
    _setSelection(side, selectionOf(side).withCity(city));
    await _loadDistricts(side, city);
  }

  /// Chooses a district, the last step before calculating.
  void selectDistrict(LocationSide side, District? district) {
    if (district == null) {
      return;
    }
    _setSelection(side, selectionOf(side).withDistrict(district));
  }

  /// Ticks or unticks a courier.
  void toggleCourier(String code) {
    if (!_courierCodes.remove(code)) {
      _courierCodes.add(code);
    }
    notifyListeners();
  }

  /// Validates and stores the typed weight.
  void setWeight(String value) {
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

  Future<Result<void>> _loadProvinces() async {
    final result = await _regionRepository.getProvinces();
    switch (result) {
      case Ok<List<Province>>(:final value):
        _provinces = value;
        notifyListeners();
        return const Ok<void>(null);
      case Failure<List<Province>>(:final error):
        return Failure<void>(error);
    }
  }

  Future<void> _loadCities(LocationSide side, Province province) async {
    final token = _startRequest(side);
    final result = await _regionRepository.getCities(province.id);
    if (!_isCurrent(side, token)) {
      return;
    }

    _loading[side] = false;
    switch (result) {
      case Ok<List<City>>(:final value):
        _errors[side] = null;
        _setSelection(side, selectionOf(side).withCities(value));
      case Failure<List<City>>(:final error):
        _errors[side] = describeError(error);
        notifyListeners();
    }
  }

  Future<void> _loadDistricts(LocationSide side, City city) async {
    final token = _startRequest(side);
    final result = await _regionRepository.getDistricts(city.id);
    if (!_isCurrent(side, token)) {
      return;
    }

    _loading[side] = false;
    switch (result) {
      case Ok<List<District>>(:final value):
        _errors[side] = null;
        _setSelection(side, selectionOf(side).withDistricts(value));
      case Failure<List<District>>(:final error):
        _errors[side] = describeError(error);
        notifyListeners();
    }
  }

  Future<Result<void>> _calculate() async {
    final originDistrict = _origin.district;
    final destinationDistrict = _destination.district;
    if (originDistrict == null || destinationDistrict == null) {
      return Failure<void>(
        const ApiException('Choose an origin and a destination district first'),
      );
    }

    final result = await _shippingCostRepository.calculateDistrictCost(
      originDistrictId: originDistrict.id,
      destinationDistrictId: destinationDistrict.id,
      weightGrams: _weightGrams,
      courierCodes: _courierCodes.toList(),
    );

    _hasCalculated = true;
    switch (result) {
      case Ok<List<DomesticShippingCost>>(:final value):
        _costs = value;
        notifyListeners();
        await _saveToHistory(value);
        return const Ok<void>(null);
      case Failure<List<DomesticShippingCost>>(:final error):
        _costs = const [];
        notifyListeners();
        return Failure<void>(error);
    }
  }

  Future<void> _saveToHistory(List<DomesticShippingCost> results) async {
    final entry = DomesticHistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      originLabel: _origin.label,
      destinationLabel: _destination.label,
      weightGrams: _weightGrams,
      courierCodes: _courierCodes.toList(),
      results: results,
    );

    final saved = await _historyRepository.add(entry);
    if (saved case Failure<void>(:final error)) {
      // A calculation the user can see is more important than its history
      // entry, so a storage failure is logged instead of surfaced.
      debugPrint('DomesticViewModel: could not save history: $error');
    }
  }

  /// Marks a new lookup for [side] and returns its token.
  ///
  /// Only the newest lookup may apply its result, so a fast change of province
  /// cannot be overwritten by an older response.
  int _startRequest(LocationSide side) {
    final token = (_requestTokens[side] ?? 0) + 1;
    _requestTokens[side] = token;
    _loading[side] = true;
    _errors[side] = null;
    notifyListeners();
    return token;
  }

  bool _isCurrent(LocationSide side, int token) =>
      _requestTokens[side] == token;

  void _setSelection(LocationSide side, LocationSelection selection) {
    if (side == LocationSide.origin) {
      _origin = selection;
    } else {
      _destination = selection;
    }
    notifyListeners();
  }
}
