import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/routing/app_router.dart';
import 'package:flutter_mvvm_x_rajaongkir/routing/app_routes.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_theme.dart';

/// The application widget: theme, routing and nothing else.
class RajaOngkirApp extends StatelessWidget {
  const RajaOngkirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shipping Cost',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
