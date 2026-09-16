import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/rajaongkir_api_service.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/country.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/domestic_destination.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/result.dart';

/// Single source of truth for the direct search method: searching an origin,
/// searching a destination country and pricing a parcel between them.
///
/// Search answers are cached per query for the session, so re-typing or
/// correcting a search does not spend the daily API quota twice.
class InternationalShippingRepository {
  InternationalShippingRepository({
    required this._apiService,
    this._maxCachedQueries = 30,
  });

  final RajaOngkirApiService _apiService;
  final int _maxCachedQueries;

  final Map<String, List<DomesticDestination>> _originCache = {};
  final Map<String, List<Country>> _countryCache = {};

  /// Searches Indonesian places to use as the shipment origin.
  Future<Result<List<DomesticDestination>>> searchOrigins(String query) {
    return _search(
      query: query,
      cache: _originCache,
      fetch: _apiService.searchDomesticDestinations,
    );
  }

  /// Searches destination countries.
  Future<Result<List<Country>>> searchCountries(String query) {
    return _search(
      query: query,
      cache: _countryCache,
      fetch: _apiService.searchInternationalDestinations,
    );
  }

  /// Calculates international prices, cheapest first.
  Future<Result<List<InternationalShippingCost>>> calculateCost({
    required int originId,
    required String countryId,
    required int weightGrams,
    required List<String> courierCodes,
  }) async {
    final result = await _apiService.calculateInternationalCost(
      originId: originId,
      countryId: countryId,
      weightGrams: weightGrams,
      courierCodes: courierCodes,
    );

    return switch (result) {
      Ok<List<InternationalShippingCost>>(:final value) =>
        Ok<List<InternationalShippingCost>>(
          [...value]..sort((a, b) => a.cost.compareTo(b.cost)),
        ),
      Failure<List<InternationalShippingCost>>() => result,
    };
  }

  Future<Result<List<T>>> _search<T>({
    required String query,
    required Map<String, List<T>> cache,
    required Future<Result<List<T>>> Function(String query) fetch,
  }) async {
    final key = query.trim().toLowerCase();
    final cached = cache[key];
    if (cached != null) {
      return Ok<List<T>>(cached);
    }

    final result = await fetch(query.trim());
    if (result case Ok<List<T>>(:final value)) {
      if (cache.length >= _maxCachedQueries) {
        cache.remove(cache.keys.first);
      }
      cache[key] = value;
    }
    return result;
  }
}
