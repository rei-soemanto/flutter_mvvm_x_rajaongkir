import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/repositories/history_repository.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_history_entry.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/formatters/error_message.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/command.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/result.dart';

/// Which entries the history list shows.
enum HistoryFilter {
  /// Everything.
  all,

  /// Only domestic calculations.
  domestic,

  /// Only international calculations.
  international,
}

/// Drives the history page.
///
/// The list is loaded once and then kept in step with the repository's change
/// stream, so a calculation made on another tab appears here immediately even
/// though all three pages stay alive inside the navigation shell.
class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({required this._historyRepository}) {
    load = Command0<void>(_load);
    _subscription = _historyRepository.changes.listen(_onEntriesChanged);
    unawaited(load.execute());
  }

  final HistoryRepository _historyRepository;

  /// Loads the saved entries.
  late final Command0<void> load;

  StreamSubscription<List<ShippingHistoryEntry>>? _subscription;
  List<ShippingHistoryEntry> _entries = const [];
  HistoryFilter _filter = HistoryFilter.all;

  /// The entries that match the current filter, newest first.
  List<ShippingHistoryEntry> get entries {
    final filtered = switch (_filter) {
      HistoryFilter.all => _entries,
      HistoryFilter.domestic =>
        _entries.where((entry) => entry.type == ShipmentType.domestic).toList(),
      HistoryFilter.international =>
        _entries
            .where((entry) => entry.type == ShipmentType.international)
            .toList(),
    };
    return List.unmodifiable(filtered);
  }

  /// How many entries are saved in total, ignoring the filter.
  int get totalCount => _entries.length;

  /// The filter currently applied.
  HistoryFilter get filter => _filter;

  /// Changes the filter.
  void setFilter(HistoryFilter filter) {
    if (filter == _filter) {
      return;
    }
    _filter = filter;
    notifyListeners();
  }

  /// Deletes one entry.
  ///
  /// Returns null when it worked, or a message to show the user.
  Future<String?> delete(String id) async {
    final result = await _historyRepository.delete(id);
    return _messageFor(result);
  }

  /// Puts a deleted entry back, used by the undo action.
  Future<String?> restore(ShippingHistoryEntry entry) async {
    final result = await _historyRepository.add(entry);
    return _messageFor(result);
  }

  /// Deletes every entry.
  Future<String?> clear() async {
    final result = await _historyRepository.clear();
    return _messageFor(result);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }

  Future<Result<void>> _load() async {
    final result = await _historyRepository.getAll();
    switch (result) {
      case Ok<List<ShippingHistoryEntry>>(:final value):
        _entries = value;
        notifyListeners();
        return const Ok<void>(null);
      case Failure<List<ShippingHistoryEntry>>(:final error):
        return Failure<void>(error);
    }
  }

  void _onEntriesChanged(List<ShippingHistoryEntry> entries) {
    _entries = entries;
    notifyListeners();
  }

  String? _messageFor(Result<void> result) => switch (result) {
    Ok<void>() => null,
    Failure<void>(:final error) => describeError(error),
  };
}
