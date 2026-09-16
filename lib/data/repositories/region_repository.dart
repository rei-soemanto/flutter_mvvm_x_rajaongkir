import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_mvvm_x_rajaongkir/config/app_config.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/local/key_value_storage_service.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/rajaongkir_api_service.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/city.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/district.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/province.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/json_reader.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/result.dart';

/// Single source of truth for the province, city and district lookups used by
/// the step-by-step method.
///
/// These lists almost never change but the free API plan allows only 100 calls
/// a day, so every list is cached in memory for the session and on the device
/// for [AppConfig.regionCacheTtl]. Concurrent calls for the same list share one
/// request, and a stale cache is still served when the network fails.
class RegionRepository {
  RegionRepository({
    required this._apiService,
    required this._storage,
    this._cacheTtl = AppConfig.regionCacheTtl,
    this._clock = DateTime.now,
  });

  final RajaOngkirApiService _apiService;
  final KeyValueStorageService _storage;
  final Duration _cacheTtl;
  final DateTime Function() _clock;

  final Map<String, Object> _memoryCache = {};
  final Map<String, Future<Object>> _inFlight = {};

  /// All provinces.
  Future<Result<List<Province>>> getProvinces() {
    return _cached(
      key: 'provinces',
      fetch: _apiService.getProvinces,
      fromJson: Province.fromJson,
      toJson: (province) => province.toJson(),
    );
  }

  /// The cities of [provinceId].
  Future<Result<List<City>>> getCities(int provinceId) {
    return _cached(
      key: 'cities.$provinceId',
      fetch: () => _apiService.getCities(provinceId),
      fromJson: City.fromJson,
      toJson: (city) => city.toJson(),
    );
  }

  /// The districts of [cityId].
  Future<Result<List<District>>> getDistricts(int cityId) {
    return _cached(
      key: 'districts.$cityId',
      fetch: () => _apiService.getDistricts(cityId),
      fromJson: District.fromJson,
      toJson: (district) => district.toJson(),
    );
  }

  /// Forgets every cached list, both in memory and on the device.
  Future<void> clearCache() async {
    final keys = _memoryCache.keys.toList();
    _memoryCache.clear();
    for (final key in keys) {
      try {
        await _storage.remove(_storageKey(key));
      } on Exception catch (error) {
        debugPrint('RegionRepository: could not clear $key: $error');
      }
    }
  }

  Future<Result<List<T>>> _cached<T>({
    required String key,
    required Future<Result<List<T>>> Function() fetch,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T value) toJson,
  }) async {
    final cached = _memoryCache[key];
    if (cached is List<T>) {
      return Ok<List<T>>(cached);
    }

    final pending = _inFlight[key];
    if (pending != null) {
      return await pending as Result<List<T>>;
    }

    final future = _load(
      key: key,
      fetch: fetch,
      fromJson: fromJson,
      toJson: toJson,
    );
    _trackInFlight(key, future);
    try {
      return await future;
    } finally {
      _clearInFlight(key);
    }
  }

  /// Registers a request so concurrent callers can share it.
  ///
  /// Kept separate and synchronous so storing the future is not mistaken for a
  /// forgotten `await`.
  void _trackInFlight(String key, Future<Object> future) {
    _inFlight[key] = future;
  }

  /// Drops a finished request. Synchronous for the same reason as
  /// [_trackInFlight]: `Map.remove` hands back the stored future.
  void _clearInFlight(String key) {
    _inFlight.remove(key);
  }

  Future<Result<List<T>>> _load<T>({
    required String key,
    required Future<Result<List<T>>> Function() fetch,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T value) toJson,
  }) async {
    final stored = await _readCache(key, fromJson);
    if (stored != null && !_isStale(stored.cachedAt)) {
      _memoryCache[key] = stored.items;
      return Ok<List<T>>(stored.items);
    }

    final result = await fetch();
    switch (result) {
      case Ok<List<T>>(:final value):
        _memoryCache[key] = value;
        await _writeCache(key, value, toJson);
        return result;
      case Failure<List<T>>():
        // Serve an expired cache rather than failing when the network is down.
        if (stored != null) {
          _memoryCache[key] = stored.items;
          return Ok<List<T>>(stored.items);
        }
        return result;
    }
  }

  bool _isStale(DateTime cachedAt) => _clock().difference(cachedAt) > _cacheTtl;

  String _storageKey(String key) => 'region_cache.$key';

  Future<_CacheEntry<T>?> _readCache<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    try {
      final raw = await _storage.readString(_storageKey(key));
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final json = asJsonMap(jsonDecode(raw));
      final cachedAt = DateTime.tryParse(readStringOr(json, 'cached_at'));
      if (cachedAt == null) {
        return null;
      }
      final items = asJsonList(json['items']).map(fromJson).toList();
      return _CacheEntry<T>(cachedAt: cachedAt, items: items);
    } on Exception catch (error) {
      debugPrint(
        'RegionRepository: ignoring unreadable cache for $key: $error',
      );
      return null;
    }
  }

  Future<void> _writeCache<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T value) toJson,
  ) async {
    try {
      final payload = jsonEncode({
        'cached_at': _clock().toIso8601String(),
        'items': items.map(toJson).toList(),
      });
      await _storage.writeString(_storageKey(key), payload);
    } on Exception catch (error) {
      debugPrint('RegionRepository: could not cache $key: $error');
    }
  }
}

class _CacheEntry<T> {
  const _CacheEntry({required this.cachedAt, required this.items});

  final DateTime cachedAt;
  final List<T> items;
}
