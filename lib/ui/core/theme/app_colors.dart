import 'package:flutter/material.dart';

/// Brand colour tokens.
///
/// Widgets never read these directly. They read roles from
/// `Theme.of(context).colorScheme`, which is generated from [seed].
abstract final class AppColors {
  /// Seed colour used to generate the light and dark Material 3 palettes.
  static const Color seed = Color(0xFF1B5E9B);
}
