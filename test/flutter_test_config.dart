import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Runs once before every test file in this folder.
///
/// Tests must never reach out to fonts.google.com: widget tests pump a plain
/// `ThemeData` rather than `AppTheme`, and this makes an accidental font fetch
/// fail loudly instead of hanging on the network.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
