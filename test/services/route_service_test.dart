import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mini_foodpanda/services/route_service.dart';

/// A minimal fake `http.Client` — avoids pulling in mocktail's `when()`
/// ceremony for a single canned response per test.
class _FakeClient extends http.BaseClient {
  _FakeClient(this._respond);
  final Future<http.StreamedResponse> Function(http.BaseRequest request) _respond;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _respond(request);
}

http.Client _clientReturning(String body, {int statusCode = 200}) {
  return _FakeClient((request) async {
    return http.StreamedResponse(Stream.value(body.codeUnits), statusCode);
  });
}

void main() {
  const restaurant = LatLng(30.05, 72.35);
  const customer = LatLng(30.06, 72.36);

  group('RouteService.fetchRoute', () {
    test('parses a valid OSRM GeoJSON response into LatLng points', () async {
      const body = '''
      {
        "routes": [
          {
            "geometry": {
              "coordinates": [[72.35, 30.05], [72.355, 30.055], [72.36, 30.06]]
            }
          }
        ]
      }
      ''';
      final points = await RouteService.fetchRoute(restaurant, customer, client: _clientReturning(body));
      expect(points, isNotNull);
      expect(points!.length, 3);
      // OSRM returns [lng, lat] — the service must flip it to LatLng(lat, lng).
      expect(points.first.latitude, 30.05);
      expect(points.first.longitude, 72.35);
      expect(points.last.latitude, 30.06);
    });

    test('returns null when the server responds with a non-200 status', () async {
      final points = await RouteService.fetchRoute(
        restaurant,
        customer,
        client: _clientReturning('', statusCode: 500),
      );
      expect(points, isNull);
    });

    test('returns null when the routes array is empty', () async {
      final points = await RouteService.fetchRoute(
        restaurant,
        customer,
        client: _clientReturning('{"routes": []}'),
      );
      expect(points, isNull);
    });

    test('returns null on malformed JSON instead of throwing', () async {
      final points = await RouteService.fetchRoute(
        restaurant,
        customer,
        client: _clientReturning('not json'),
      );
      expect(points, isNull);
    });
  });
}
