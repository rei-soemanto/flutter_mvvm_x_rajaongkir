import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/routing/app_routes.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/domestic/view_models/domestic_view_model.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/history/view_models/history_detail_view_model.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/history/view_models/history_view_model.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/history/views/history_detail_page.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/international/view_models/international_view_model.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/main_shell/view_models/main_shell_view_model.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/main_shell/views/main_shell_page.dart';
import 'package:provider/provider.dart';

/// Builds the route for a name, and creates the view models that route needs.
///
/// View models are created here rather than inside widgets, so each page gets
/// its dependencies from the repositories registered in `main.dart` and is
/// disposed with its route.
abstract final class AppRouter {
  /// Handles every named route in the app.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
      case AppRoutes.domestic:
        return _shellRoute(settings, AppTab.domestic);
      case AppRoutes.international:
        return _shellRoute(settings, AppTab.international);
      case AppRoutes.history:
        return _shellRoute(settings, AppTab.history);
      case AppRoutes.historyDetail:
        final entryId = settings.arguments;
        if (entryId is! String) {
          return _notFoundRoute(
            settings,
            'Opening a saved calculation needs its id.',
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => ChangeNotifierProvider(
            create: (context) => HistoryDetailViewModel(
              historyRepository: context.read(),
              entryId: entryId,
            ),
            child: const HistoryDetailPage(),
          ),
        );
      default:
        return _notFoundRoute(
          settings,
          'No page is registered for ${settings.name}.',
        );
    }
  }

  /// The navigation shell, opened on [tab].
  static MaterialPageRoute<void> _shellRoute(
    RouteSettings settings,
    AppTab tab,
  ) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => MainShellViewModel(initialTab: tab),
          ),
          ChangeNotifierProvider(
            create: (context) => DomesticViewModel(
              regionRepository: context.read(),
              shippingCostRepository: context.read(),
              historyRepository: context.read(),
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => InternationalViewModel(
              repository: context.read(),
              historyRepository: context.read(),
            ),
          ),
          ChangeNotifierProvider(
            create: (context) =>
                HistoryViewModel(historyRepository: context.read()),
          ),
        ],
        child: const MainShellPage(),
      ),
    );
  }

  static MaterialPageRoute<void> _notFoundRoute(
    RouteSettings settings,
    String message,
  ) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xlg),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }
}
