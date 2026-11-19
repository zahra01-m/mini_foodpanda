import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/core/utils/maps_launcher.dart';

void main() {
  test('directionsUri targets the coordinate on Google Maps', () {
    final uri = directionsUri(lat: 30.0453, lng: 72.3489);
    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['destination'], '30.0453,72.3489');
  });
}
