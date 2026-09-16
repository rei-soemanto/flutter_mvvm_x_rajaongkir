/// Test doubles shared by the repository, view model and widget tests.
///
/// They use `implements`, so no production class needs an extra interface just
/// to be testable.
library;

import 'dart:async';

import 'package:flutter_mvvm_x_rajaongkir/data/repositories/history_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/repositories/international_shipping_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/repositories/region_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/repositories/shipping_cost_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/local/key_value_storage_service.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/api_exception.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/rajaongkir_api_service.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/city.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/country.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/district.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/domestic_destination.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/province.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_history_entry.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/result.dart';

/// Sample data the tests build on.
const jakarta = Province(id: 11, name: 'DKI JAKARTA');
const bali = Province(id: 1, name: 'BALI');
const jakartaSelatan = City(id: 1360, name: 'JAKARTA SELATAN', zipCode: '0');
const jagakarsa = District(id: 1361, name: 'JAGAKARSA', zipCode: '12630');
const denpasar = City(id: 114, name: 'DENPASAR', zipCode: '80111');
const kuta = District(id: 2100, name: 'KUTA', zipCode: '80361');

const jneReg = DomesticShippingCost(
  name: 'Jalur Nugraha Ekakurir (JNE)',
  code: 'jne',
  service: 'REG',
  description: 'Layanan Reguler',
  cost: 10000,
  etd: '1-2 day',
);

const posEconomy = DomesticShippingCost(
  name: 'POS Indonesia',
  code: 'pos',
  service: 'Pos Ekonomi',
  description: 'Pos Ekonomi',
  cost: 7000,
  etd: '4-6 day',
);

const sleman = DomesticDestination(
  id: 31555,
  label: 'SINDUHARJO, NGAGLIK, SLEMAN, DI YOGYAKARTA, 55581',
  provinceName: 'DI YOGYAKARTA',
  cityName: 'SLEMAN',
  districtName: 'NGAGLIK',
  subdistrictName: 'SINDUHARJO',
  zipCode: '55581',
);

const malaysia = Country(id: '108', name: 'Malaysia');

const tikiWpx = InternationalShippingCost(
  name: 'Citra Van Titipan Kilat (TIKI)',
  code: 'tiki',
  service: 'WPX',
  description: 'World Parcel Express',
  cost: 130008,
  etd: '-',
  currency: 'IDR',
  currencyUpdatedAt: '30-12-2024',
  currencyValue: 16251,
);

const posInternational = InternationalShippingCost(
  name: 'POS Indonesia',
  code: 'pos',
  service: 'Paket Cepat Internasional',
  description: 'Express',
  cost: 250000,
  etd: '3-5 day',
  currency: 'IDR',
);

const rayExpress = InternationalShippingCost(
  name: 'Rayspeed Indonesia',
  code: 'ray',
  service: 'Regular Service',
  description: 'Retail',
  cost: 300000,
  etd: '2 day',
  currency: 'IDR',
);

/// Key-value storage that lives in memory.
class InMemoryKeyValueStorageService implements KeyValueStorageService {
  /// Everything written so far.
  final Map<String, String> values = {};

  /// Makes every write fail, to test the error paths.
  bool failOnWrite = false;

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> writeString(String key, String value) async {
    if (failOnWrite) {
      throw const StorageException('storage is full');
    }
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

/// An API service that answers from canned data and counts its calls.
class FakeRajaOngkirApiService implements RajaOngkirApiService {
  /// Provinces returned by [getProvinces].
  List<Province> provinces = const [jakarta, bali];

  /// Cities per province id.
  Map<int, List<City>> cities = const {
    11: [jakartaSelatan],
    1: [denpasar],
  };

  /// Districts per city id.
  Map<int, List<District>> districts = const {
    1360: [jagakarsa],
    114: [kuta],
  };

  /// When set, every lookup fails with this error.
  Exception? failure;

  /// Completer used to hold a request open until a test releases it.
  Completer<void>? gate;

  /// How many times each method was called, keyed by name.
  final Map<String, int> calls = {};

  @override
  Future<Result<List<Province>>> getProvinces() =>
      _answer('getProvinces', provinces);

  @override
  Future<Result<List<City>>> getCities(int provinceId) =>
      _answer('getCities', cities[provinceId] ?? const []);

  @override
  Future<Result<List<District>>> getDistricts(int cityId) =>
      _answer('getDistricts', districts[cityId] ?? const []);

  @override
  Future<Result<List<DomesticDestination>>> searchDomesticDestinations(
    String search, {
    int limit = 10,
  }) => _answer('searchDomesticDestinations', const [sleman]);

  @override
  Future<Result<List<Country>>> searchInternationalDestinations(
    String search, {
    int limit = 20,
  }) => _answer('searchInternationalDestinations', const [malaysia]);

  @override
  Future<Result<List<DomesticShippingCost>>> calculateDistrictDomesticCost({
    required int originDistrictId,
    required int destinationDistrictId,
    required int weightGrams,
    required List<String> courierCodes,
  }) => _answer('calculateDistrictDomesticCost', const [jneReg, posEconomy]);

  @override
  Future<Result<List<InternationalShippingCost>>> calculateInternationalCost({
    required int originId,
    required String countryId,
    required int weightGrams,
    required List<String> courierCodes,
  }) =>
      _answer('calculateInternationalCost', const [tikiWpx, posInternational]);

  @override
  void dispose() {}

  Future<Result<List<T>>> _answer<T>(String name, List<T> value) async {
    calls[name] = (calls[name] ?? 0) + 1;
    final gate = this.gate;
    if (gate != null) {
      await gate.future;
    }
    final failure = this.failure;
    if (failure != null) {
      return Failure<List<T>>(failure);
    }
    return Ok<List<T>>(value);
  }
}

/// A region repository that answers instantly from canned data.
class FakeRegionRepository implements RegionRepository {
  /// Provinces to return.
  List<Province> provinces = const [jakarta, bali];

  /// Cities per province id.
  Map<int, List<City>> cities = const {
    11: [jakartaSelatan],
    1: [denpasar],
  };

  /// Districts per city id.
  Map<int, List<District>> districts = const {
    1360: [jagakarsa],
    114: [kuta],
  };

  /// When set, every lookup fails with this error.
  Exception? failure;

  @override
  Future<Result<List<Province>>> getProvinces() async =>
      failure != null ? Failure(failure!) : Ok(provinces);

  @override
  Future<Result<List<City>>> getCities(int provinceId) async =>
      failure != null ? Failure(failure!) : Ok(cities[provinceId] ?? const []);

  @override
  Future<Result<List<District>>> getDistricts(int cityId) async =>
      failure != null ? Failure(failure!) : Ok(districts[cityId] ?? const []);

  @override
  Future<void> clearCache() async {}
}

/// A cost repository that returns canned prices and records what it was asked.
class FakeShippingCostRepository implements ShippingCostRepository {
  /// Prices to return, already sorted as the real repository would.
  List<DomesticShippingCost> costs = const [posEconomy, jneReg];

  /// When set, the calculation fails with this error.
  Exception? failure;

  /// Arguments of the last call.
  int? lastOriginId;
  int? lastDestinationId;
  int? lastWeightGrams;
  List<String>? lastCourierCodes;

  @override
  Future<Result<List<DomesticShippingCost>>> calculateDistrictCost({
    required int originDistrictId,
    required int destinationDistrictId,
    required int weightGrams,
    required List<String> courierCodes,
  }) async {
    lastOriginId = originDistrictId;
    lastDestinationId = destinationDistrictId;
    lastWeightGrams = weightGrams;
    lastCourierCodes = courierCodes;
    return failure != null ? Failure(failure!) : Ok(costs);
  }
}

/// An international repository whose searches can be held open.
class FakeInternationalShippingRepository
    implements InternationalShippingRepository {
  /// Origins returned per query.
  Map<String, List<DomesticDestination>> origins = const {};

  /// Countries returned per query.
  Map<String, List<Country>> countries = const {};

  /// Prices returned by [calculateCost].
  List<InternationalShippingCost> costs = const [
    posInternational,
    rayExpress,
    tikiWpx,
  ];

  /// When set, every call fails with this error.
  Exception? failure;

  /// Gates keyed by query, so a test can decide which search finishes first.
  final Map<String, Completer<void>> gates = {};

  /// Queries received, in order.
  final List<String> searchedCountries = [];

  @override
  Future<Result<List<DomesticDestination>>> searchOrigins(String query) async {
    await gates[query]?.future;
    return failure != null
        ? Failure(failure!)
        : Ok(origins[query] ?? const [sleman]);
  }

  @override
  Future<Result<List<Country>>> searchCountries(String query) async {
    searchedCountries.add(query);
    await gates[query]?.future;
    return failure != null
        ? Failure(failure!)
        : Ok(countries[query] ?? const [malaysia]);
  }

  @override
  Future<Result<List<InternationalShippingCost>>> calculateCost({
    required int originId,
    required String countryId,
    required int weightGrams,
    required List<String> courierCodes,
  }) async => failure != null ? Failure(failure!) : Ok(costs);
}

/// A history repository that keeps entries in a list.
class FakeHistoryRepository implements HistoryRepository {
  /// Everything saved so far, newest first.
  List<ShippingHistoryEntry> entries = [];

  /// When set, every call fails with this error.
  Exception? failure;

  final StreamController<List<ShippingHistoryEntry>> _controller =
      StreamController<List<ShippingHistoryEntry>>.broadcast();

  @override
  Stream<List<ShippingHistoryEntry>> get changes => _controller.stream;

  @override
  Future<Result<List<ShippingHistoryEntry>>> getAll() async =>
      failure != null ? Failure(failure!) : Ok(List.of(entries));

  @override
  Future<Result<void>> add(ShippingHistoryEntry entry) async {
    if (failure != null) {
      return Failure(failure!);
    }
    entries = [entry, ...entries];
    _controller.add(List.of(entries));
    return const Ok<void>(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (failure != null) {
      return Failure(failure!);
    }
    entries = entries.where((entry) => entry.id != id).toList();
    _controller.add(List.of(entries));
    return const Ok<void>(null);
  }

  @override
  Future<Result<void>> clear() async {
    if (failure != null) {
      return Failure(failure!);
    }
    entries = [];
    _controller.add(const []);
    return const Ok<void>(null);
  }

  @override
  void dispose() {
    unawaited(_controller.close());
  }
}
