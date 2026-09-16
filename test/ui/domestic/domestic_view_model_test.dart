import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/api_exception.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_history_entry.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/domestic/view_models/domestic_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes.dart';

void main() {
  group('DomesticViewModel', () {
    late FakeRegionRepository regionRepository;
    late FakeShippingCostRepository costRepository;
    late FakeHistoryRepository historyRepository;

    DomesticViewModel build() => DomesticViewModel(
      regionRepository: regionRepository,
      shippingCostRepository: costRepository,
      historyRepository: historyRepository,
    );

    Future<DomesticViewModel> buildLoaded() async {
      final viewModel = build();
      await viewModel.loadProvinces.execute();
      return viewModel;
    }

    /// Fills in one side down to its district.
    Future<void> complete(
      DomesticViewModel viewModel,
      LocationSide side,
    ) async {
      await viewModel.selectProvince(side, jakarta);
      await viewModel.selectCity(side, jakartaSelatan);
      viewModel.selectDistrict(side, jagakarsa);
    }

    setUp(() {
      regionRepository = FakeRegionRepository();
      costRepository = FakeShippingCostRepository();
      historyRepository = FakeHistoryRepository();
    });

    test('loads the provinces when it is created', () async {
      final viewModel = await buildLoaded();

      expect(viewModel.provinces, [jakarta, bali]);
    });

    test('loads cities after a province is chosen', () async {
      final viewModel = await buildLoaded();

      await viewModel.selectProvince(LocationSide.origin, jakarta);

      expect(viewModel.origin.province, jakarta);
      expect(viewModel.origin.cities, [jakartaSelatan]);
      expect(viewModel.isSideLoading(LocationSide.origin), isFalse);
    });

    test('loads districts after a city is chosen', () async {
      final viewModel = await buildLoaded();
      await viewModel.selectProvince(LocationSide.origin, jakarta);

      await viewModel.selectCity(LocationSide.origin, jakartaSelatan);

      expect(viewModel.origin.districts, [jagakarsa]);
    });

    test('clears the city and district when the province changes', () async {
      final viewModel = await buildLoaded();
      await complete(viewModel, LocationSide.origin);
      expect(viewModel.origin.isComplete, isTrue);

      await viewModel.selectProvince(LocationSide.origin, bali);

      expect(viewModel.origin.city, isNull);
      expect(viewModel.origin.district, isNull);
      expect(viewModel.origin.districts, isEmpty);
      expect(viewModel.origin.cities, [denpasar]);
    });

    test('keeps the two sides independent', () async {
      final viewModel = await buildLoaded();

      await complete(viewModel, LocationSide.origin);

      expect(viewModel.destination.province, isNull);
      expect(viewModel.destination.cities, isEmpty);
    });

    test('reports a lookup failure for that side only', () async {
      final viewModel = await buildLoaded();
      regionRepository.failure = const ApiNetworkException('offline');

      await viewModel.selectProvince(LocationSide.origin, jakarta);

      expect(viewModel.sideError(LocationSide.origin), isNotNull);
      expect(viewModel.sideError(LocationSide.destination), isNull);
      expect(viewModel.isSideLoading(LocationSide.origin), isFalse);
    });

    test('allows calculating only once the form is complete', () async {
      final viewModel = await buildLoaded();
      expect(viewModel.canCalculate, isFalse);

      await complete(viewModel, LocationSide.origin);
      expect(viewModel.canCalculate, isFalse);

      await complete(viewModel, LocationSide.destination);
      expect(viewModel.canCalculate, isTrue);
    });

    test('refuses a weight that is not a positive number', () async {
      final viewModel = await buildLoaded();
      await complete(viewModel, LocationSide.origin);
      await complete(viewModel, LocationSide.destination);

      viewModel.setWeight('abc');
      expect(viewModel.weightError, isNotNull);
      expect(viewModel.canCalculate, isFalse);

      viewModel.setWeight('1500');
      expect(viewModel.weightError, isNull);
      expect(viewModel.weightGrams, 1500);
      expect(viewModel.canCalculate, isTrue);
    });

    test('needs at least one courier', () async {
      final viewModel = await buildLoaded();
      await complete(viewModel, LocationSide.origin);
      await complete(viewModel, LocationSide.destination);

      for (final code in viewModel.courierCodes.toList()) {
        viewModel.toggleCourier(code);
      }

      expect(viewModel.courierCodes, isEmpty);
      expect(viewModel.canCalculate, isFalse);
    });

    test('sends the chosen districts, weight and couriers', () async {
      final viewModel = await buildLoaded();
      await complete(viewModel, LocationSide.origin);
      await viewModel.selectProvince(LocationSide.destination, bali);
      await viewModel.selectCity(LocationSide.destination, denpasar);
      viewModel.selectDistrict(LocationSide.destination, kuta);
      viewModel.setWeight('2000');

      await viewModel.calculate.execute();

      expect(costRepository.lastOriginId, jagakarsa.id);
      expect(costRepository.lastDestinationId, kuta.id);
      expect(costRepository.lastWeightGrams, 2000);
      expect(costRepository.lastCourierCodes, viewModel.courierCodes.toList());
    });

    test('keeps the results and marks the cheapest', () async {
      final viewModel = await buildLoaded();
      await complete(viewModel, LocationSide.origin);
      await complete(viewModel, LocationSide.destination);

      await viewModel.calculate.execute();

      expect(viewModel.calculate.completed, isTrue);
      expect(viewModel.costs, [posEconomy, jneReg]);
      expect(viewModel.cheapest, posEconomy);
      expect(viewModel.hasCalculated, isTrue);
    });

    test('saves the calculation to the history', () async {
      final viewModel = await buildLoaded();
      await complete(viewModel, LocationSide.origin);
      await complete(viewModel, LocationSide.destination);

      await viewModel.calculate.execute();

      final entry = historyRepository.entries.single;
      expect(entry, isA<DomesticHistoryEntry>());
      expect(entry.type, ShipmentType.domestic);
      expect(entry.originLabel, contains('JAGAKARSA'));
      expect(entry.results, [posEconomy, jneReg]);
    });

    test('still reports success when the history cannot be saved', () async {
      final viewModel = await buildLoaded();
      await complete(viewModel, LocationSide.origin);
      await complete(viewModel, LocationSide.destination);
      historyRepository.failure = const StorageException('disk full');

      await viewModel.calculate.execute();

      expect(viewModel.calculate.completed, isTrue);
      expect(viewModel.costs, isNotEmpty);
    });

    test('surfaces a calculation failure and empties the results', () async {
      final viewModel = await buildLoaded();
      await complete(viewModel, LocationSide.origin);
      await complete(viewModel, LocationSide.destination);
      costRepository.failure = const TooManyRequestsException('quota');

      await viewModel.calculate.execute();

      expect(viewModel.calculate.failed, isTrue);
      expect(viewModel.calculate.error, isA<TooManyRequestsException>());
      expect(viewModel.costs, isEmpty);
      expect(viewModel.hasCalculated, isTrue);
    });
  });
}
