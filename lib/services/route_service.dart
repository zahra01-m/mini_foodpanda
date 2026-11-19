import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Road route between two points from the public OSRM demo server — free
/// and needs no API key, unlike Google's Directions API. Returns null on
/// any failure so the map can fall back to a straight line between the
/// two Google Maps markers. (The demo server is fine for a portfolio
/// project; self-host OSRM, or switch to the Directions API, for a real
/// production app.)
class RouteService {
  RouteService._();

  /// [client] is injectable so tests can supply a fake `http.Client`
  /// instead of hitting the real OSRM server.
  static Future<List<LatLng>?> fetchRoute(LatLng from, LatLng to, {http.Client? client}) async {
    final httpClient = client ?? http.Client();
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await httpClient.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map;
      final routes = body['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final geometry = (routes.first as Map)['geometry'] as Map;
      final coords = geometry['coordinates'] as List;
      return coords.map<LatLng>((c) {
        final p = c as List;
        return LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble());
      }).toList();
    } catch (_) {
      return null;
    } finally {
      // Only close a client we created ourselves — a caller-supplied
      // client (real or fake) is theirs to manage and may be reused.
      if (client == null) httpClient.close();
    }
  }
}
