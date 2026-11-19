import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../core/theme/app_palette.dart';

/// On Android / iOS the Google map works out of the box. On **web** it also
/// needs the Google Maps JavaScript script in `web/index.html` plus a web
/// API key; without them the page crashes with
/// "TypeError: Cannot read properties of undefined (reading 'maps')".
///
/// So on web the map is opt-in: after following the web section of
/// MAPS_SETUP.md, run/build with `--dart-define=WEB_MAPS=true`.
const bool _webMapsEnabled = bool.fromEnvironment('WEB_MAPS');

bool get mapsAvailable => !kIsWeb || _webMapsEnabled;

/// Friendly stand-in shown where a map would be when [mapsAvailable] is false.
class MapUnavailable extends StatelessWidget {
  final double height;
  final String message;

  const MapUnavailable({
    super.key,
    required this.height,
    this.message = 'The live map is available in the Android and iOS apps.',
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.beige1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.line),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 32, color: p.redDeep),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: p.inkSoft, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
