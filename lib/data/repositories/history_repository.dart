import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_mvvm_x_rajaongkir/config/app_config.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/local/key_value_storage_service.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/api_exception.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_history_entry.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/json_reader.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/result.dart';

/// Single source of truth for saved calculations.
///
/// The domestic and international view models write here after a successful
/// calculation, and the history page reads from here. Because all three pages
/// stay alive inside the navigation shell, every change is also published on
/// [changes] so the history list updates while another tab is in front.
class HistoryRepository {
  HistoryRepository({
    required this._storage,
    this._limit = AppConfig.historyLimit,
  });

  /// Storage key holding the encoded entry list.
  static const String storageKey = 'shipping_history_v1';

  final KeyValueStorageService _storage;
  final int _limit;

  final StreamController<List<ShippingHistoryEntry>> _controller =
      StreamController<List<ShippingHistoryEntry>>.broadcast();

  List<ShippingHistoryEntry>? _cache;

  /// Emits the full list every time an entry is added, deleted or cleared.
  Stream<List<ShippingHistoryEntry>> get changes => _controller.stream;

  /// Every saved entry, newest first.
  Future<Result<List<ShippingHistoryEntry>>> getAll() async {
    final cached = _cache;
    if (cached != null) {
      return Ok<List<ShippingHistoryEntry>>(cached);
    }

    try {
      final raw = await _storage.readString(storageKey);
      final entries = _decode(raw);
      _cache = entries;
      return Ok<List<ShippingHistoryEntry>>(entries);
    } on Exception catch (error) {
      return Failure<List<ShippingHistoryEntry>>(
        StorageException('Could not read the history: $error', cause: error),
      );
    }
  }

  /// Saves [entry] at the top of the list, dropping the oldest entries beyond
  /// the configured limit.
  Future<Result<void>> add(ShippingHistoryEntry entry) async {
    final current = await getAll();
    if (current case Failure<List<ShippingHistoryEntry>>(:final error)) {
      return Failure<void>(error);
    }

    final entries = [entry, ...current.asOk.value];
    return _persist(
      entries.length > _limit ? entries.sublist(0, _limit) : entries,
    );
  }

  /// Removes the entry with [id].
  Future<Result<void>> delete(String id) async {
    final current = await getAll();
    if (current case Failure<List<ShippingHistoryEntry>>(:final error)) {
      return Failure<void>(error);
    }

    final entries = current.asOk.value
        .where((entry) => entry.id != id)
        .toList();
    return _persist(entries);
  }

  /// Removes every entry.
  Future<Result<void>> clear() => _persist(const []);

  /// Closes the change stream.
  void dispose() {
    unawaited(_controller.close());
  }

  Future<Result<void>> _persist(List<ShippingHistoryEntry> entries) async {
    try {
      final payload = jsonEncode(
        entries.map((entry) => entry.toJson()).toList(),
      );
      await _storage.writeString(storageKey, payload);
      _cache = entries;
      if (_controller.hasListener) {
        _controller.add(entries);
      }
      return const Ok<void>(null);
    } on Exception catch (error) {
      return Failure<void>(
        StorageException('Could not save the history: $error', cause: error),
      );
    }
  }

  List<ShippingHistoryEntry> _decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    final entries = <ShippingHistoryEntry>[];
    for (final item in decoded) {
      try {
        entries.add(ShippingHistoryEntry.fromJson(asJsonMap(item)));
      } on FormatException catch (error) {
        // One unreadable entry must not discard the rest of the history.
        debugPrint('HistoryRepository: skipping unreadable entry: $error');
      }
    }
    return entries;
  }
}
