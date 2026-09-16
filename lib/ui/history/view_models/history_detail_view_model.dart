import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/repositories/history_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/api_exception.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_history_entry.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/command.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/result.dart';

/// Drives the page that reopens one saved calculation.
class HistoryDetailViewModel extends ChangeNotifier {
  HistoryDetailViewModel({
    required this._historyRepository,
    required this.entryId,
  }) {
    load = Command0<void>(_load);
    unawaited(load.execute());
  }

  final HistoryRepository _historyRepository;

  /// Id of the entry to show, taken from the route arguments.
  final String entryId;

  /// Loads the entry.
  late final Command0<void> load;

  ShippingHistoryEntry? _entry;

  /// The entry, once it has been loaded.
  ShippingHistoryEntry? get entry => _entry;

  Future<Result<void>> _load() async {
    final result = await _historyRepository.getAll();
    switch (result) {
      case Ok<List<ShippingHistoryEntry>>(:final value):
        for (final entry in value) {
          if (entry.id == entryId) {
            _entry = entry;
            notifyListeners();
            return const Ok<void>(null);
          }
        }
        return Failure<void>(
          const ApiException('That saved calculation no longer exists'),
        );
      case Failure<List<ShippingHistoryEntry>>(:final error):
        return Failure<void>(error);
    }
  }
}
