import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens.
///
/// The external font is Plus Jakarta Sans, loaded through the `google_fonts`
/// package. Every Material 3 slot the app uses is defined here and registered
/// in [textTheme], so widgets always read a style from
/// `Theme.of(context).textTheme` instead of writing `TextStyle` inline.
abstract final class AppTextStyle {
  static TextStyle _style(
    double size,
    double height,
    FontWeight weight,
    double letterSpacing,
  ) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      height: height,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
  }

  /// 57 px display style.
  static final TextStyle displayLarge = _style(
    57,
    1.12,
    FontWeight.w400,
    -0.25,
  );

  /// 45 px display style.
  static final TextStyle displayMedium = _style(45, 1.16, FontWeight.w400, 0);

  /// 36 px display style.
  static final TextStyle displaySmall = _style(36, 1.22, FontWeight.w400, 0);

  /// 32 px headline style.
  static final TextStyle headlineLarge = _style(32, 1.25, FontWeight.w600, 0);

  /// 28 px headline style.
  static final TextStyle headlineMedium = _style(28, 1.29, FontWeight.w600, 0);

  /// 24 px headline style, used by dialog titles.
  static final TextStyle headlineSmall = _style(24, 1.33, FontWeight.w600, 0);

  /// 22 px title style, used by the app bar.
  static final TextStyle titleLarge = _style(22, 1.27, FontWeight.w600, 0);

  /// 16 px title style, used by card titles.
  static final TextStyle titleMedium = _style(16, 1.5, FontWeight.w600, 0.15);

  /// 14 px title style, used by section headers.
  static final TextStyle titleSmall = _style(14, 1.43, FontWeight.w600, 0.1);

  /// 16 px body style.
  static final TextStyle bodyLarge = _style(16, 1.5, FontWeight.w400, 0.5);

  /// 14 px body style, the default for most text.
  static final TextStyle bodyMedium = _style(14, 1.43, FontWeight.w400, 0.25);

  /// 12 px body style, used by captions.
  static final TextStyle bodySmall = _style(12, 1.33, FontWeight.w400, 0.4);

  /// 14 px label style, used by buttons and chips.
  static final TextStyle labelLarge = _style(14, 1.43, FontWeight.w600, 0.1);

  /// 12 px label style, used by the navigation bar.
  static final TextStyle labelMedium = _style(12, 1.33, FontWeight.w500, 0.5);

  /// 11 px label style, used for raw JSON keys in the detail pop-ups.
  static final TextStyle labelSmall = _style(11, 1.45, FontWeight.w500, 0.5);

  /// All slots above, ready for `ThemeData.textTheme`.
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
