import 'dart:async';

import 'package:flutter_mvvm_x_rajaongkir/data/repositories/region_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/api_exception.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes.dart';

void main() {
  group('RegionRepository', () {
    late FakeRajaOngkirApiService apiService;
    late InMemoryKeyValueStorageService storage;
    late DateTime now;

    RegionRepository build() => RegionRepository(
      apiService: apiService,
      storage: storage,
      cacheTtl: const Duration(days: 7),
      clock: () => now,
    );

    setUp(() {
      apiService = FakeRajaOngkirApiService();
      storage = InMemoryKeyValueStorageService();
      now = DateTime(2026, 9, 16, 12);
    });

    test('asks the API once and then serves from memory', () async {
      final repository = build();

      await repository.getProvinces();
      final second = await repository.getProvinces();

      expect(apiService.calls['getProvinces'], 1);
      expect(second.asOk.value, [jakarta, bali]);
    });

    test('serves a later session from the stored cache', () async {
      await build().getProvinces();
      expect(apiService.calls['getProvinces'], 1);

      // A new repository stands in for a restarted app.
      final result = await build().getProvinces();

      expect(apiService.calls['getProvinces'], 1);
      expect(result.asOk.value, [jakarta, bali]);
    });

    test('asks again once the cache has expired', () async {
      await build().getProvinces();

      now = now.add(const Duration(days: 8));
      await build().getProvinces();

      expect(apiService.calls['getProvinces'], 2);
    });

    test(
      'shares one request between callers asking at the same time',
      () async {
        final repository = build();
        apiService.gate = Completer<void>();

        final first = repository.getCities(11);
        final second = repository.getCities(11);
        apiService.gate!.complete();
        await Future.wait([first, second]);

        expect(apiService.calls['getCities'], 1);
      },
    );

    test('keeps separate caches per province', () async {
      final repository = build();

      await repository.getCities(11);
      await repository.getCities(1);

      expect(apiService.calls['getCities'], 2);
      expect((await repository.getCities(1)).asOk.value, [denpasar]);
    });

    test('falls back to an expired cache when the network fails', () async {
      await build().getProvinces();
      now = now.add(const Duration(days: 30));
      apiService.failure = const ApiNetworkException('offline');

      final result = await build().getProvinces();

      expect(result, isA<Ok<dynamic>>());
      expect(result.asOk.value, [jakarta, bali]);
    });

    test('reports the failure when there is no cache at all', () async {
      apiService.failure = const ApiNetworkException('offline');

      final result = await build().getProvinces();

      expect(result.asFailure.error, isA<ApiNetworkException>());
    });

    test('ignores a cache entry that cannot be read', () async {
      storage.values['region_cache.provinces'] = 'not json';

      final result = await build().getProvinces();

      expect(result.asOk.value, [jakarta, bali]);
      expect(apiService.calls['getProvinces'], 1);
    });
  });
}
