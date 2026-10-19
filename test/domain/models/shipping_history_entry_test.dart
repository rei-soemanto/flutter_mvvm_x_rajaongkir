import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_history_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes.dart';

void main() {
  group('ShippingHistoryEntry.cheapest', () {
    // Two or more results are needed: reduce never calls its callback on a
    // single element, which is how a covariant list type error slipped past.
    test('finds the cheapest domestic result', () {
      final entry = DomesticHistoryEntry(
        id: '1',
        createdAt: DateTime(2026, 9, 16),
        originLabel: 'JAGAKARSA',
        destinationLabel: 'KUTA',
        weightGrams: 1000,
        courierCodes: const ['jne', 'pos'],
        results: const [jneReg, posEconomy],
      );

      expect(entry.cheapest, same(posEconomy));
    });

    test('finds the cheapest international result', () {
      final entry = InternationalHistoryEntry(
        id: '2',
        createdAt: DateTime(2026, 9, 16),
        originLabel: 'SLEMAN',
        destinationLabel: 'Malaysia',
        weightGrams: 500,
        courierCodes: const ['pos', 'tiki', 'ray'],
        results: const [posInternational, tikiWpx, rayExpress],
      );

      expect(entry.cheapest, same(tikiWpx));
    });

    test('is null when there are no results', () {
      final entry = DomesticHistoryEntry(
        id: '3',
        createdAt: DateTime(2026, 9, 16),
        originLabel: 'JAGAKARSA',
        destinationLabel: 'KUTA',
        weightGrams: 1000,
        courierCodes: const ['jne'],
        results: const [],
      );

      expect(entry.cheapest, isNull);
    });
  });
}
