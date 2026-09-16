import 'dart:async';
import 'dart:convert';

import 'package:flutter_mvvm_x_rajaongkir/config/app_config.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/api_exception.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/rajaongkir_endpoints.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/city.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/country.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/district.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/domestic_destination.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/province.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/json_reader.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/result.dart';
import 'package:http/http.dart' as http;

/// Wraps the RajaOngkir Shipping Cost API.
///
/// This is the only class in the app that speaks HTTP. It holds no state, one
/// method matches one endpoint, and every method returns a [Result] so callers
/// never have to catch exceptions.
///
/// Every response is the same envelope:
/// `{"meta": {"message", "code", "status"}, "data": ...}`.
class RajaOngkirApiService {
  RajaOngkirApiService({
    http.Client? client,
    this._baseUrl = AppConfig.rajaOngkirBaseUrl,
    this._apiKey = AppConfig.rajaOngkirApiKey,
    this._timeout = AppConfig.requestTimeout,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;
  final String _apiKey;
  final Duration _timeout;

  /// Search Province: every province in Indonesia.
  Future<Result<List<Province>>> getProvinces() {
    return _requestList(
      path: RajaOngkirEndpoints.provinces,
      parse: Province.fromJson,
    );
  }

  /// Search City: the cities of [provinceId].
  Future<Result<List<City>>> getCities(int provinceId) {
    return _requestList(
      path: RajaOngkirEndpoints.cities(provinceId),
      parse: City.fromJson,
    );
  }

  /// Search District: the districts of [cityId].
  Future<Result<List<District>>> getDistricts(int cityId) {
    return _requestList(
      path: RajaOngkirEndpoints.districts(cityId),
      parse: District.fromJson,
    );
  }

  /// Search Domestic Destination: places matching [search].
  ///
  /// The returned ids are what the international calculation expects as
  /// `origin`.
  Future<Result<List<DomesticDestination>>> searchDomesticDestinations(
    String search, {
    int limit = 10,
  }) {
    return _requestList(
      path: RajaOngkirEndpoints.domesticDestinations,
      query: {'search': search, 'limit': '$limit'},
      parse: DomesticDestination.fromJson,
      emptyWhenNotFound: true,
    );
  }

  /// Search International Destination: countries matching [search].
  Future<Result<List<Country>>> searchInternationalDestinations(
    String search, {
    int limit = 20,
  }) {
    return _requestList(
      path: RajaOngkirEndpoints.internationalDestinations,
      query: {'search': search, 'limit': '$limit'},
      parse: Country.fromJson,
      emptyWhenNotFound: true,
    );
  }

  /// District Calculate Cost: prices between two districts.
  Future<Result<List<DomesticShippingCost>>> calculateDistrictDomesticCost({
    required int originDistrictId,
    required int destinationDistrictId,
    required int weightGrams,
    required List<String> courierCodes,
  }) {
    return _requestList(
      method: _HttpMethod.post,
      path: RajaOngkirEndpoints.districtDomesticCost,
      body: {
        'origin': '$originDistrictId',
        'destination': '$destinationDistrictId',
        'weight': '$weightGrams',
        'courier': courierCodes.join(':'),
      },
      parse: DomesticShippingCost.fromJson,
    );
  }

  /// Calculate International Cost: prices from a domestic origin to a country.
  Future<Result<List<InternationalShippingCost>>> calculateInternationalCost({
    required int originId,
    required String countryId,
    required int weightGrams,
    required List<String> courierCodes,
  }) {
    return _requestList(
      method: _HttpMethod.post,
      path: RajaOngkirEndpoints.internationalCost,
      body: {
        'origin': '$originId',
        'destination': countryId,
        'weight': '$weightGrams',
        'courier': courierCodes.join(':'),
      },
      parse: InternationalShippingCost.fromJson,
    );
  }

  /// Closes the HTTP client when this service created it.
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  /// Sends one request and decodes its `data` array into a list of [T].
  ///
  /// [emptyWhenNotFound] turns the "Data not found" answer of the search
  /// endpoints into an empty list, because an empty search result is not an
  /// error.
  Future<Result<List<T>>> _requestList<T>({
    required String path,
    required T Function(Map<String, dynamic> json) parse,
    _HttpMethod method = _HttpMethod.get,
    Map<String, String>? query,
    Map<String, String>? body,
    bool emptyWhenNotFound = false,
  }) async {
    if (_apiKey.trim().isEmpty) {
      return Failure<List<T>>(const MissingApiKeyException());
    }

    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: query?.isEmpty ?? true ? null : query);
    final headers = <String, String>{
      'key': _apiKey,
      'Accept': 'application/json',
    };

    try {
      final request = switch (method) {
        _HttpMethod.get => _client.get(uri, headers: headers),
        _HttpMethod.post => _client.post(uri, headers: headers, body: body),
      };
      final response = await request.timeout(_timeout);
      return _decodeList(response, parse, emptyWhenNotFound);
    } on TimeoutException catch (error) {
      return Failure<List<T>>(
        ApiTimeoutException(
          'Request to $path timed out after ${_timeout.inSeconds}s',
          cause: error,
        ),
      );
    } on http.ClientException catch (error) {
      return Failure<List<T>>(ApiNetworkException(error.message, cause: error));
    } on FormatException catch (error) {
      return Failure<List<T>>(ApiDecodeException(error.message, cause: error));
    } on ApiException catch (error) {
      return Failure<List<T>>(error);
    }
  }

  Result<List<T>> _decodeList<T>(
    http.Response response,
    T Function(Map<String, dynamic> json) parse,
    bool emptyWhenNotFound,
  ) {
    // A wrong route answers `404 page not found` as plain text, so the content
    // type is checked before the body is decoded.
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('json')) {
      return Failure<List<T>>(
        ApiHttpException.fromStatus(
          response.statusCode,
          response.body.trim().isEmpty
              ? 'Unexpected empty response'
              : response.body.trim(),
        ),
      );
    }

    final envelope = asJsonMap(jsonDecode(response.body));
    final meta = asJsonMap(envelope['meta']);
    final code = readIntOrNull(meta, 'code') ?? response.statusCode;
    final message = readStringOr(
      meta,
      'message',
      fallback: 'Request failed with status $code',
    );

    if (code == 404 && emptyWhenNotFound) {
      return Ok<List<T>>(const []);
    }
    if (code < 200 || code >= 300) {
      return Failure<List<T>>(ApiHttpException.fromStatus(code, message));
    }

    final data = envelope['data'];
    if (data == null) {
      return Ok<List<T>>(const []);
    }
    return Ok<List<T>>(asJsonList(data).map(parse).toList());
  }
}

enum _HttpMethod { get, post }
