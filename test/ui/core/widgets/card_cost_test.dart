import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/card_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/cost_details.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/fakes.dart';

/// Pumps [child] with a plain theme, so no test reaches out for a font.
Widget wrap(Widget child) => MaterialApp(
  theme: ThemeData(),
  home: Scaffold(body: child),
);

void main() {
  group('CardCost', () {
    testWidgets('shows the courier, service, price and estimate', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const CardCost(cost: jneReg)));

      expect(find.text('Jalur Nugraha Ekakurir (JNE): REG'), findsOneWidget);
      expect(find.text('Layanan Reguler'), findsOneWidget);
      expect(find.text('Rp10.000'), findsOneWidget);
      expect(find.text('1-2 days'), findsOneWidget);
    });

    testWidgets('says so when the courier gives no estimate', (tester) async {
      await tester.pumpWidget(wrap(const CardCost(cost: tikiWpx)));

      expect(find.text('Not specified'), findsOneWidget);
    });

    testWidgets('shows a badge only when one is given', (tester) async {
      await tester.pumpWidget(
        wrap(const CardCost(cost: jneReg, badge: 'Best price')),
      );

      expect(find.text('Best price'), findsOneWidget);
    });

    testWidgets('reports a tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(CardCost(cost: jneReg, onTap: () => taps++)),
      );

      await tester.tap(find.byType(CardCost));
      expect(taps, 1);
    });
  });

  group('the detail pop-up', () {
    testWidgets('opens a bottom sheet listing every domestic attribute', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CardCost(
              cost: jneReg,
              onTap: () => showShippingCostDetails(context, jneReg),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CardCost));
      await tester.pumpAndSettle();

      // Every key of the District Calculate Cost response, and the values the
      // assignment asks for, starting with description.
      for (final key in [
        'name',
        'code',
        'service',
        'description',
        'cost',
        'etd',
      ]) {
        expect(find.text(key), findsOneWidget, reason: 'missing the $key row');
      }
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Layanan Reguler'), findsWidgets);
      expect(find.text('JNE'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('opens a dialog for an international result', (tester) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CardCost(
              cost: tikiWpx,
              onTap: () => showShippingCostDetails(context, tikiWpx),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CardCost));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('description'), findsOneWidget);
      expect(find.text('currency_updated_at'), findsOneWidget);
      expect(find.text('30-12-2024'), findsOneWidget);
      expect(find.text('16.251'), findsOneWidget);
    });

    testWidgets('leaves out the currency fields a courier did not send', (
      tester,
    ) async {
      const withoutRate = InternationalShippingCost(
        name: 'POS Indonesia',
        code: 'pos',
        service: 'Express',
        description: 'Express',
        cost: 250000,
        etd: '3-5 day',
        currency: 'IDR',
      );

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CardCost(
              cost: withoutRate,
              onTap: () => showShippingCostDetails(context, withoutRate),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CardCost));
      await tester.pumpAndSettle();

      expect(find.text('currency'), findsOneWidget);
      expect(find.text('currency_updated_at'), findsNothing);
      expect(find.text('currency_value'), findsNothing);
    });
  });
}
