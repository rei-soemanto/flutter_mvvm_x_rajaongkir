import 'dart:convert';

import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/api_exception.dart';
import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/rajaongkir_api_service.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/country.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/province.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _envelope(Object? data, {int code = 200}) => {
  'meta': {'message': 'Success', 'code': code, 'status': 'success'},
  'data': data,
};

void main() {
  group('RajaOngkirApiService', () {
    test('sends the key header and parses the province list', () async {
      late http.BaseRequest captured;
      final client = MockClient((request) async {
        captured = request;
        return _json(
          _envelope([
            {'id': 11, 'name': 'DKI JAKARTA'},
          ]),
        );
      });

      final result = await RajaOngkirApiService(
        client: client,
        apiKey: 'test-key',
      ).getProvinces();

      expect(result, isA<Ok<List<Province>>>());
      expect(
        result.asOk.value.single,
        const Province(id: 11, name: 'DKI JAKARTA'),
      );
      expect(captured.headers['key'], 'test-key');
      expect(captured.url.path, endsWith('/destination/province'));
      expect(captured.method, 'GET');
    });

    test('puts the province id in the city path', () async {
      late Uri captured;
      final client = MockClient((request) async {
        captured = request.url;
        return _json(_envelope(const []));
      });

      await RajaOngkirApiService(client: client, apiKey: 'k').getCities(11);

      expect(captured.path, endsWith('/destination/city/11'));
    });

    test('sends a search as query parameters, not inside the path', () async {
      late Uri captured;
      final client = MockClient((request) async {
        captured = request.url;
        return _json(
          _envelope([
            {'country_id': '108', 'country_name': 'Malaysia'},
          ]),
        );
      });

      final result = await RajaOngkirApiService(
        client: client,
        apiKey: 'k',
      ).searchInternationalDestinations('malaysia', limit: 5);

      expect(captured.path, endsWith('/destination/international-destination'));
      expect(captured.queryParameters['search'], 'malaysia');
      expect(captured.queryParameters['limit'], '5');
      expect(
        result.asOk.value.single,
        const Country(id: '108', name: 'Malaysia'),
      );
    });

    test(
      'posts the district cost as form fields with joined couriers',
      () async {
        late http.Request captured;
        final client = MockClient((request) async {
          captured = request;
          return _json(
            _envelope([
              {
                'name': 'Jalur Nugraha Ekakurir (JNE)',
                'code': 'jne',
                'service': 'REG',
                'description': 'Layanan Reguler',
                'cost': 10000,
                'etd': '1-2 day',
              },
            ]),
          );
        });

        final result = await RajaOngkirApiService(client: client, apiKey: 'k')
            .calculateDistrictDomesticCost(
              originDistrictId: 1391,
              destinationDistrictId: 2100,
              weightGrams: 1500,
              courierCodes: const ['jne', 'pos', 'tiki'],
            );

        expect(captured.method, 'POST');
        expect(
          captured.headers['content-type'],
          contains('application/x-www-form-urlencoded'),
        );
        expect(captured.bodyFields, {
          'origin': '1391',
          'destination': '2100',
          'weight': '1500',
          'courier': 'jne:pos:tiki',
        });
        expect(result.asOk.value.single.description, 'Layanan Reguler');
        expect(result.asOk.value.single.cost, 10000);
      },
    );

    test(
      'parses the optional currency fields of an international cost',
      () async {
        final client = MockClient(
          (request) async => _json(
            _envelope([
              {
                'name': 'Rayspeed Indonesia',
                'code': 'ray',
                'service': 'Regular Service',
                'description': 'Retail',
                'currency': 'IDR',
                'cost': 55000,
                'etd': '',
              },
              {
                'name': 'Citra Van Titipan Kilat (TIKI)',
                'code': 'tiki',
                'service': 'WPX',
                'description': 'World Parcel Express',
                'currency': 'IDR',
                'cost': 130008,
                'etd': '-',
                'currency_updated_at': '30-12-2024',
                'currency_value': 16251,
              },
            ]),
          ),
        );

        final result = await RajaOngkirApiService(client: client, apiKey: 'k')
            .calculateInternationalCost(
              originId: 17521,
              countryId: '152',
              weightGrams: 500,
              courierCodes: const ['tiki'],
            );

        final costs = result.asOk.value;
        expect(costs.first.currencyUpdatedAt, isNull);
        expect(costs.first.currencyValue, isNull);
        expect(costs.last.currencyUpdatedAt, '30-12-2024');
        expect(costs.last.currencyValue, 16251);
      },
    );

    test(
      'fails without calling the network when no key was supplied',
      () async {
        var called = false;
        final client = MockClient((request) async {
          called = true;
          return _json(_envelope(const []));
        });

        final result = await RajaOngkirApiService(
          client: client,
          apiKey: '   ',
        ).getProvinces();

        expect(called, isFalse);
        expect(result.asFailure.error, isA<MissingApiKeyException>());
      },
    );

    test('maps a missing key answer to UnauthorizedException', () async {
      final client = MockClient(
        (request) async => _json({
          'meta': {
            'message': 'Invalid API key or key not found',
            'code': 401,
            'status': 'failed',
          },
          'data': null,
        }, status: 401),
      );

      final result = await RajaOngkirApiService(
        client: client,
        apiKey: 'wrong',
      ).getProvinces();

      final error = result.asFailure.error;
      expect(error, isA<UnauthorizedException>());
      expect((error as ApiException).statusCode, 401);
    });

    test('maps an invalid key answer, which arrives as 400', () async {
      final client = MockClient(
        (request) async => _json({
          'meta': {
            'message': 'Invalid Api key, key not found',
            'code': 400,
            'status': 'failed',
          },
          'data': null,
        }, status: 400),
      );

      final result = await RajaOngkirApiService(
        client: client,
        apiKey: 'wrong',
      ).getProvinces();

      expect(result.asFailure.error, isA<UnauthorizedException>());
    });

    test('handles the plain text 404 of an unknown route', () async {
      final client = MockClient(
        (request) async => http.Response(
          '404 page not found',
          404,
          headers: {'content-type': 'text/plain'},
        ),
      );

      final result = await RajaOngkirApiService(
        client: client,
        apiKey: 'k',
      ).getProvinces();

      final error = result.asFailure.error;
      expect(error, isA<NotFoundException>());
      expect((error as ApiException).message, '404 page not found');
    });

    test('turns a not found search into an empty list', () async {
      final client = MockClient(
        (request) async => _json({
          'meta': {
            'message': 'International Destinations Data not found',
            'code': 404,
            'status': 'error',
          },
          'data': null,
        }, status: 404),
      );

      final result = await RajaOngkirApiService(
        client: client,
        apiKey: 'k',
      ).searchInternationalDestinations('zzzzz');

      expect(result, isA<Ok<List<Country>>>());
      expect(result.asOk.value, isEmpty);
    });

    test('maps a validation answer to ValidationException', () async {
      final client = MockClient(
        (request) async => _json({
          'meta': {
            'message': 'search: cannot be blank.',
            'code': 422,
            'status': 'error',
          },
          'data': null,
        }, status: 422),
      );

      final result = await RajaOngkirApiService(
        client: client,
        apiKey: 'k',
      ).searchDomesticDestinations('');

      expect(result.asFailure.error, isA<ValidationException>());
    });

    test('maps a lost connection to ApiNetworkException', () async {
      final client = MockClient(
        (request) async => throw http.ClientException('connection closed'),
      );

      final result = await RajaOngkirApiService(
        client: client,
        apiKey: 'k',
      ).getProvinces();

      expect(result.asFailure.error, isA<ApiNetworkException>());
    });

    test('gives up after the timeout', () async {
      final client = MockClient(
        (request) async => Future<http.Response>.delayed(
          const Duration(milliseconds: 200),
          () => _json(_envelope(const [])),
        ),
      );

      final result = await RajaOngkirApiService(
        client: client,
        apiKey: 'k',
        timeout: const Duration(milliseconds: 10),
      ).getProvinces();

      expect(result.asFailure.error, isA<ApiTimeoutException>());
    });

    test('reports an unreadable body as a decode failure', () async {
      final client = MockClient(
        (request) async => http.Response(
          'not json at all',
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await RajaOngkirApiService(
        client: client,
        apiKey: 'k',
      ).getProvinces();

      expect(result.asFailure.error, isA<ApiDecodeException>());
    });

    test('treats a null data field as an empty list', () async {
      final client = MockClient((request) async => _json(_envelope(null)));

      final result = await RajaOngkirApiService(
        client: client,
        apiKey: 'k',
      ).getProvinces();

      expect(result.asOk.value, isEmpty);
    });
  });

  group('DomesticShippingCost', () {
    test('keeps every documented attribute for the detail pop-up', () {
      final cost = DomesticShippingCost.fromJson(const {
        'name': 'Lion Parcel',
        'code': 'lion',
        'service': 'JAGOPACK',
        'description': 'Economy Service',
        'cost': 7000,
        'etd': '1-4 day',
      });

      expect(cost.apiAttributes.keys, [
        'name',
        'code',
        'service',
        'description',
        'cost',
        'etd',
      ]);
      expect(cost.apiAttributes['description'], 'Economy Service');
      expect(cost.estimatedDays, 1);
    });

    test('survives the quirks the API is known to send', () {
      final cost = DomesticShippingCost.fromJson(const {
        'name': 'POS Indonesia',
        'code': 'pos',
        'service': 'Pos Reguler',
        // The API really does send numeric text here.
        'description': 240,
        'cost': 12500.0,
        'etd': '',
      });

      expect(cost.description, '240');
      expect(cost.cost, 12500);
      expect(cost.estimatedDays, isNull);
    });
  });
}
