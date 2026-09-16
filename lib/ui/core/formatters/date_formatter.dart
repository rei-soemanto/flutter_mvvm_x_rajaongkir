/// Formats the timestamps shown in the shipping history.
library;

import 'package:intl/intl.dart';

final DateFormat _historyDate = DateFormat('d MMM yyyy, HH:mm');

/// Formats [value] as `5 Sep 2026, 14:30`.
String formatHistoryDate(DateTime value) => _historyDate.format(value);
