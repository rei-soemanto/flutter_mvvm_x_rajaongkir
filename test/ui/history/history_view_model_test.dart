import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/api_exception.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_history_entry.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/history/view_models/history_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes.dart';

DomesticHistoryEntry domesticEntry(String id) => DomesticHistoryEntry(
  id: id,
  createdAt: DateTime(2026, 9, 16, 9),
  originLabel: 'JAGAKARSA',
  destinationLabel: 'KUTA',
  weightGrams: 1000,
  courierCodes: const ['jne'],
  results: const [jneReg],
);

InternationalHistoryEntry internationalEntry(String id) =>
    InternationalHistoryEntry(
      id: id,
      createdAt: DateTime(2026, 9, 16, 10),
      originLabel: 'SLEMAN',
      destinationLabel: 'Malaysia',
      weightGrams: 500,
      courierCodes: const ['pos'],
      results: const [posInternational],
    );

void main() {
  group('HistoryViewModel', () {
    late FakeHistoryRepository repository;

    Future<HistoryViewModel> buildLoaded() async {
      final viewModel = HistoryViewModel(historyRepository: repository);
      await viewModel.load.execute();
      return viewModel;
    }

    setUp(() => repository = FakeHistoryRepository());

    test('loads the saved entries', () async {
      repository.entries = [domesticEntry('1')];

      final viewModel = await buildLoaded();

      expect(viewModel.entries.single.id, '1');
      expect(viewModel.totalCount, 1);
    });

    test('filters by shipment type', () async {
      repository.entries = [internationalEntry('2'), domesticEntry('1')];
      final viewModel = await buildLoaded();

      viewModel.setFilter(HistoryFilter.domestic);
      expect(viewModel.entries.map((entry) => entry.id), ['1']);

      viewModel.setFilter(HistoryFilter.international);
      expect(viewModel.entries.map((entry) => entry.id), ['2']);

      viewModel.setFilter(HistoryFilter.all);
      expect(viewModel.entries.length, 2);
      expect(viewModel.totalCount, 2);
    });

    test('picks up an entry saved on another page', () async {
      final viewModel = await buildLoaded();
      expect(viewModel.entries, isEmpty);

      // This is what the domestic page does after a calculation.
      await repository.add(domesticEntry('1'));
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.entries.single.id, '1');
    });

    test('deletes and restores an entry', () async {
      final entry = domesticEntry('1');
      repository.entries = [entry];
      final viewModel = await buildLoaded();

      expect(await viewModel.delete('1'), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.entries, isEmpty);

      expect(await viewModel.restore(entry), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.entries.single.id, '1');
    });

    test('clears everything', () async {
      repository.entries = [domesticEntry('1'), domesticEntry('2')];
      final viewModel = await buildLoaded();

      expect(await viewModel.clear(), isNull);
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.entries, isEmpty);
    });

    test('returns a message when a delete fails', () async {
      repository.entries = [domesticEntry('1')];
      final viewModel = await buildLoaded();
      repository.failure = const StorageException('disk full');

      expect(await viewModel.delete('1'), isNotNull);
    });

    test('reports a load failure through the command', () async {
      repository.failure = const StorageException('unreadable');

      final viewModel = await buildLoaded();

      expect(viewModel.load.failed, isTrue);
      expect(viewModel.entries, isEmpty);
    });
  });
}
