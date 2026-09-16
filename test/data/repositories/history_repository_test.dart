import 'package:flutter_mvvm_x_rajaongkir/data/repositories/history_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/api_exception.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_history_entry.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes.dart';

DomesticHistoryEntry entry(String id) => DomesticHistoryEntry(
  id: id,
  createdAt: DateTime(2026, 9, 16, 10),
  originLabel: 'JAGAKARSA, JAKARTA SELATAN',
  destinationLabel: 'KUTA, DENPASAR',
  weightGrams: 1000,
  courierCodes: const ['jne'],
  results: const [jneReg],
);

void main() {
  group('HistoryRepository', () {
    late InMemoryKeyValueStorageService storage;

    setUp(() => storage = InMemoryKeyValueStorageService());

    test('saves entries newest first', () async {
      final repository = HistoryRepository(storage: storage);

      await repository.add(entry('1'));
      await repository.add(entry('2'));

      final saved = (await repository.getAll()).asOk.value;
      expect(saved.map((item) => item.id), ['2', '1']);
    });

    test('keeps the list within the limit', () async {
      final repository = HistoryRepository(storage: storage, limit: 2);

      await repository.add(entry('1'));
      await repository.add(entry('2'));
      await repository.add(entry('3'));

      final saved = (await repository.getAll()).asOk.value;
      expect(saved.map((item) => item.id), ['3', '2']);
    });

    test('survives a restart', () async {
      await HistoryRepository(storage: storage).add(entry('1'));

      final saved = (await HistoryRepository(
        storage: storage,
      ).getAll()).asOk.value;

      expect(saved.single.id, '1');
      expect(saved.single.results.single.description, 'Layanan Reguler');
    });

    test('deletes one entry and clears them all', () async {
      final repository = HistoryRepository(storage: storage);
      await repository.add(entry('1'));
      await repository.add(entry('2'));

      await repository.delete('1');
      expect((await repository.getAll()).asOk.value.map((item) => item.id), [
        '2',
      ]);

      await repository.clear();
      expect((await repository.getAll()).asOk.value, isEmpty);
    });

    test('publishes every change so other pages can follow', () async {
      final repository = HistoryRepository(storage: storage);
      final seen = <int>[];
      final subscription = repository.changes.listen(
        (entries) => seen.add(entries.length),
      );

      await repository.add(entry('1'));
      await repository.add(entry('2'));
      await repository.delete('1');

      // Stream events are delivered asynchronously, so let them land.
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      repository.dispose();
      expect(seen, [1, 2, 1]);
    });

    test('skips an unreadable entry instead of losing the rest', () async {
      final good = entry('1');
      storage.values[HistoryRepository.storageKey] =
          '[{"type":"domestic","id":"broken"},${_encode(good)}]';

      final saved = (await HistoryRepository(
        storage: storage,
      ).getAll()).asOk.value;

      expect(saved.single.id, '1');
    });

    test('reports a storage failure instead of throwing', () async {
      storage.failOnWrite = true;

      final result = await HistoryRepository(storage: storage).add(entry('1'));

      expect(result, isA<Failure<void>>());
      expect(result.asFailure.error, isA<StorageException>());
    });
  });
}

String _encode(DomesticHistoryEntry entry) {
  final json = entry.toJson();
  final results = (json['results'] as List<dynamic>).first;
  return '{"type":"domestic","id":"${json['id']}",'
      '"created_at":"${json['created_at']}",'
      '"origin_label":"${json['origin_label']}",'
      '"destination_label":"${json['destination_label']}",'
      '"weight_grams":${json['weight_grams']},'
      '"courier_codes":["jne"],'
      '"results":[${_encodeResult(results as Map<String, dynamic>)}]}';
}

String _encodeResult(Map<String, dynamic> result) {
  return '{"name":"${result['name']}","code":"${result['code']}",'
      '"service":"${result['service']}",'
      '"description":"${result['description']}",'
      '"cost":${result['cost']},"etd":"${result['etd']}"}';
}
