import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/app.dart';
import 'package:flutter_mvvm_x_rajaongkir/config/dependencies.dart';
import 'package:provider/provider.dart';

/// Starts the app with the dependency graph in place.
///
/// The RajaOngkir key is read at build time, so run the app with:
///
/// ```sh
/// flutter run --dart-define-from-file=config/env.json
/// ```
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(providers: buildAppProviders(), child: const RajaOngkirApp()),
  );
}
