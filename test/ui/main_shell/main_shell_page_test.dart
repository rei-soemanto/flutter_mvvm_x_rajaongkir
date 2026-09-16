import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/domestic/view_models/domestic_view_model.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/domestic/views/domestic_page.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/history/view_models/history_view_model.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/history/views/history_page.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/international/view_models/international_view_model.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/international/views/international_page.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/main_shell/view_models/main_shell_view_model.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/main_shell/views/main_shell_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../testing/fakes.dart';

void main() {
  group('MainShellPage', () {
    late FakeRegionRepository regionRepository;
    late FakeShippingCostRepository costRepository;
    late FakeInternationalShippingRepository internationalRepository;
    late FakeHistoryRepository historyRepository;

    setUp(() {
      regionRepository = FakeRegionRepository();
      costRepository = FakeShippingCostRepository();
      internationalRepository = FakeInternationalShippingRepository();
      historyRepository = FakeHistoryRepository();
    });

    Future<void> pumpShell(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainShellViewModel()),
            ChangeNotifierProvider(
              create: (_) => DomesticViewModel(
                regionRepository: regionRepository,
                shippingCostRepository: costRepository,
                historyRepository: historyRepository,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => InternationalViewModel(
                repository: internationalRepository,
                historyRepository: historyRepository,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  HistoryViewModel(historyRepository: historyRepository),
            ),
          ],
          // A plain theme keeps google_fonts out of the test.
          child: MaterialApp(theme: ThemeData(), home: const MainShellPage()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('has one bottom navigation item per page', (tester) async {
      await pumpShell(tester);

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Domestic'), findsWidgets);
      expect(find.text('International'), findsWidgets);
      expect(find.text('History'), findsWidgets);
    });

    testWidgets('opens on the domestic page', (tester) async {
      await pumpShell(tester);

      expect(find.byType(DomesticPage), findsOneWidget);
      expect(
        find.text('Step by step: province, city, then district.'),
        findsOneWidget,
      );
    });

    testWidgets('switches pages when a tab is tapped', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.byIcon(Icons.public_outlined));
      await tester.pumpAndSettle();
      expect(
        find.text('Direct search: type a place and a country.'),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.history_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Nothing saved yet'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.local_shipping_outlined));
      await tester.pumpAndSettle();
      expect(
        find.text('Step by step: province, city, then district.'),
        findsOneWidget,
      );
    });

    testWidgets('keeps all three pages alive while switching', (tester) async {
      await pumpShell(tester);

      // An IndexedStack keeps the other pages mounted, so a filled in form is
      // still there after a trip to another tab. The hidden pages are offstage,
      // which finders skip unless asked not to.
      expect(find.byType(DomesticPage), findsOneWidget);
      expect(
        find.byType(InternationalPage, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byType(HistoryPage, skipOffstage: false), findsOneWidget);
    });
  });
}
