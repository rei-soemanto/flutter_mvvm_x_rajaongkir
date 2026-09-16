import 'dart:async';

import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/api_exception.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/country.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_history_entry.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/international/view_models/international_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes.dart';

void main() {
  group('InternationalViewModel', () {
    late FakeInternationalShippingRepository repository;
    late FakeHistoryRepository historyRepository;

    // A zero debounce makes the searches run immediately, so the tests do not
    // have to wait out a timer.
    InternationalViewModel build() => InternationalViewModel(
      repository: repository,
      historyRepository: historyRepository,
      debounce: Duration.zero,
    );

    Future<InternationalViewModel> buildReady() async {
      final viewModel = build();
      viewModel.onOriginQueryChanged('sleman');
      viewModel.onCountryQueryChanged('malaysia');
      await Future<void>.delayed(Duration.zero);
      viewModel.selectOrigin(sleman);
      viewModel.selectCountry(malaysia);
      return viewModel;
    }

    setUp(() {
      repository = FakeInternationalShippingRepository();
      historyRepository = FakeHistoryRepository();
    });

    test('ignores a search shorter than three characters', () async {
      final viewModel = build();

      viewModel.onCountryQueryChanged('ma');
      await Future<void>.delayed(Duration.zero);

      expect(repository.searchedCountries, isEmpty);
      expect(viewModel.countryResults, isEmpty);
    });

    test('shows what a search found', () async {
      final viewModel = build();

      viewModel.onCountryQueryChanged('malaysia');
      await Future<void>.delayed(Duration.zero);

      expect(repository.searchedCountries, ['malaysia']);
      expect(viewModel.countryResults, [malaysia]);
      expect(viewModel.isSearchingCountry, isFalse);
    });

    test(
      'applies the newest search even if an older one answers last',
      () async {
        final viewModel = build();
        const singapore = Country(id: '200', name: 'Singapore');
        repository
          ..countries = const {
            'malaysia': [malaysia],
            'singapore': [singapore],
          }
          ..gates['malaysia'] = Completer<void>();

        // The slow search starts first, then a newer one overtakes it.
        viewModel.onCountryQueryChanged('malaysia');
        await Future<void>.delayed(Duration.zero);
        viewModel.onCountryQueryChanged('singapore');
        await Future<void>.delayed(Duration.zero);
        repository.gates['malaysia']!.complete();
        await Future<void>.delayed(Duration.zero);

        expect(viewModel.countryResults, [singapore]);
      },
    );

    test('reports a search failure', () async {
      final viewModel = build();
      repository.failure = const ApiNetworkException('offline');

      viewModel.onCountryQueryChanged('malaysia');
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.countryError, isNotNull);
      expect(viewModel.countryResults, isEmpty);
    });

    test('a preset sets the weight, typing switches to custom', () async {
      final viewModel = build();

      viewModel.selectPreset(ParcelPreset.document);
      expect(viewModel.weightGrams, 500);

      viewModel.setWeight('2500');
      expect(viewModel.preset, ParcelPreset.custom);
      expect(viewModel.weightGrams, 2500);
    });

    test('can only calculate once both ends are chosen', () async {
      final viewModel = build();
      expect(viewModel.canCalculate, isFalse);

      viewModel.selectOrigin(sleman);
      expect(viewModel.canCalculate, isFalse);

      viewModel.selectCountry(malaysia);
      expect(viewModel.canCalculate, isTrue);
    });

    test('sorts by price or by speed', () async {
      final viewModel = await buildReady();

      await viewModel.calculate.execute();

      // TIKI 130008, POS 250000, Rayspeed 300000.
      expect(viewModel.results.map((cost) => cost.code), [
        'tiki',
        'pos',
        'ray',
      ]);

      viewModel.setSort(CostSort.fastest);
      // Rayspeed says 2 days, POS says 3-5 days, TIKI gives no estimate.
      expect(viewModel.results.map((cost) => cost.code), [
        'ray',
        'pos',
        'tiki',
      ]);
    });

    test('marks the cheapest and the fastest', () async {
      final viewModel = await buildReady();

      await viewModel.calculate.execute();

      expect(viewModel.badgeFor(tikiWpx), 'Best price');
      expect(viewModel.badgeFor(rayExpress), 'Fastest');
      expect(viewModel.badgeFor(posInternational), isNull);
    });

    test('saves the calculation to the history', () async {
      final viewModel = await buildReady();

      await viewModel.calculate.execute();

      final entry = historyRepository.entries.single;
      expect(entry, isA<InternationalHistoryEntry>());
      expect(entry.destinationLabel, 'Malaysia');
      expect(entry.originLabel, sleman.shortLabel);
    });

    test('surfaces a calculation failure', () async {
      final viewModel = await buildReady();
      repository.failure = const ValidationException('Invalid Courier');

      await viewModel.calculate.execute();

      expect(viewModel.calculate.failed, isTrue);
      expect(viewModel.results, isEmpty);
    });
  });
}
