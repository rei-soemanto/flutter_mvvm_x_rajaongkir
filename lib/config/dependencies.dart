import 'package:flutter_mvvm_x_rajaongkir/data/repositories/history_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/repositories/international_shipping_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/repositories/region_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/repositories/shipping_cost_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/local/key_value_storage_service.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/rajaongkir_api_service.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Builds the app wide dependency graph: services first, then the repositories
/// that use them.
///
/// View models are not created here; the router creates them per route so each
/// page owns its own state.
List<SingleChildWidget> buildAppProviders({
  RajaOngkirApiService? apiService,
  KeyValueStorageService? storage,
}) {
  return [
    Provider<RajaOngkirApiService>(
      create: (context) => apiService ?? RajaOngkirApiService(),
      dispose: (context, service) => service.dispose(),
    ),
    Provider<KeyValueStorageService>(
      create: (context) => storage ?? SharedPreferencesStorageService(),
    ),
    Provider<RegionRepository>(
      create: (context) =>
          RegionRepository(apiService: context.read(), storage: context.read()),
    ),
    Provider<ShippingCostRepository>(
      create: (context) => ShippingCostRepository(apiService: context.read()),
    ),
    Provider<InternationalShippingRepository>(
      create: (context) =>
          InternationalShippingRepository(apiService: context.read()),
    ),
    Provider<HistoryRepository>(
      create: (context) => HistoryRepository(storage: context.read()),
      dispose: (context, repository) => repository.dispose(),
    ),
  ];
}
