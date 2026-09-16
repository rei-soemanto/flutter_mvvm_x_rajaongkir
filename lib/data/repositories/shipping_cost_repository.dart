import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/rajaongkir_api_service.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/result.dart';

/// Single source of truth for domestic shipping prices.
///
/// Results are not cached: a price is what the user asked for right now.
class ShippingCostRepository {
  ShippingCostRepository({required this._apiService});

  final RajaOngkirApiService _apiService;

  /// Calculates prices between two districts, cheapest first.
  Future<Result<List<DomesticShippingCost>>> calculateDistrictCost({
    required int originDistrictId,
    required int destinationDistrictId,
    required int weightGrams,
    required List<String> courierCodes,
  }) async {
    final result = await _apiService.calculateDistrictDomesticCost(
      originDistrictId: originDistrictId,
      destinationDistrictId: destinationDistrictId,
      weightGrams: weightGrams,
      courierCodes: courierCodes,
    );

    return switch (result) {
      Ok<List<DomesticShippingCost>>(:final value) =>
        Ok<List<DomesticShippingCost>>(
          [...value]..sort((a, b) => a.cost.compareTo(b.cost)),
        ),
      Failure<List<DomesticShippingCost>>() => result,
    };
  }
}
