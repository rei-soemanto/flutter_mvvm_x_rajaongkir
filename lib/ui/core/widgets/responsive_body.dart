import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';

/// Keeps page content readable when the window is wide.
///
/// Without this, forms and lists stretch across a desktop window. The content
/// is centred and capped at [AppSpacing.maxContentWidth].
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    required this.child,
    super.key,
    this.maxWidth = AppSpacing.maxContentWidth,
  });

  /// The page content.
  final Widget child;

  /// Width the content stops growing at.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
