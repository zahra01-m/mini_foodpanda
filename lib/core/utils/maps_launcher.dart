import 'package:url_launcher/url_launcher.dart';

/// Google Maps turn-by-turn directions link to a coordinate. Works on
/// Android / iOS (opens the Maps app when installed) and on web.
Uri directionsUri({required double lat, required double lng}) => Uri.https(
      'www.google.com',
      '/maps/dir/',
      {'api': '1', 'destination': '$lat,$lng', 'travelmode': 'driving'},
    );

/// Opens directions in the Maps app / browser. Returns false when nothing
/// could handle the link, so the caller can tell the person.
Future<bool> openDirections({required double lat, required double lng}) async {
  try {
    return await launchUrl(directionsUri(lat: lat, lng: lng), mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
