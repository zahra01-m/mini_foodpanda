import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_palette.dart';
import 'map_unavailable.dart';
import '../providers/location_provider.dart';
import '../services/route_service.dart';

/// The real Google Maps SDK (see MAPS_SETUP.md for the API keys this
/// needs). Shows the restaurant, the drop-off point, the road route
/// between them, and the rider's real position from Firestore
/// `riderLocations`, updating live as the rider's phone reports GPS.
class LiveTrackingMap extends ConsumerStatefulWidget {
  final String riderId;
  final LatLng restaurant;
  final LatLng customer;

  /// True once the food is picked up (ETA counts to the customer);
  /// false while the rider is still heading to the restaurant.
  final bool headingToCustomer;
  final double height;

  const LiveTrackingMap({
    super.key,
    required this.riderId,
    required this.restaurant,
    required this.customer,
    this.headingToCustomer = true,
    this.height = 240,
  });

  @override
  ConsumerState<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends ConsumerState<LiveTrackingMap> {
  GoogleMapController? _controller;
  List<LatLng>? _route;
  bool _fitted = false;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final route = await RouteService.fetchRoute(widget.restaurant, widget.customer);
    if (!mounted) return;
    setState(() => _route = route);
  }

  void _fitBounds(GoogleMapController controller) {
    final points = [widget.restaurant, widget.customer];
    final south = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final north = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final west = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final east = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east)),
        56,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(riderLocationProvider(widget.riderId)).valueOrNull;
    final riderPoint = loc == null ? null : LatLng(loc.lat, loc.lng);
    final routePoints = _route ?? [widget.restaurant, widget.customer];
    final p = context.palette;

    String status;
    if (riderPoint == null) {
      status = 'Waiting for rider location…';
    } else {
      final target = widget.headingToCustomer ? widget.customer : widget.restaurant;
      final meters = Geolocator.distanceBetween(
        riderPoint.latitude, riderPoint.longitude, target.latitude, target.longitude,
      );
      // ~20 km/h average city speed.
      final minutes = (meters / 1000 / 20 * 60).ceil();
      if (meters < 100) {
        status = widget.headingToCustomer ? 'Arriving now' : 'At the restaurant';
      } else {
        final m = minutes < 1 ? 1 : minutes;
        status = widget.headingToCustomer ? '$m min away' : '$m min to restaurant';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!mapsAvailable)
          MapUnavailable(height: widget.height)
        else
          ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: widget.height,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: widget.restaurant, zoom: 13),
              onMapCreated: (controller) {
                _controller = controller;
                if (!_fitted) {
                  _fitted = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds(controller));
                }
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: routePoints,
                  width: 4,
                  color: AppColors.redDeep,
                ),
              },
              markers: {
                Marker(
                  markerId: const MarkerId('restaurant'),
                  position: widget.restaurant,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                  infoWindow: const InfoWindow(title: 'Restaurant'),
                ),
                Marker(
                  markerId: const MarkerId('customer'),
                  position: widget.customer,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  infoWindow: const InfoWindow(title: 'Delivery address'),
                ),
                if (riderPoint != null)
                  Marker(
                    markerId: const MarkerId('rider'),
                    position: riderPoint,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    infoWindow: const InfoWindow(title: 'Rider'),
                    zIndex: 2,
                  ),
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Live status on its own line, then a legend that matches the three
        // map markers (the old "You" label was wrong on the rider's screen
        // and the rider marker had no legend entry at all).
        Row(
          children: [
            Icon(Icons.delivery_dining_rounded, size: 18, color: p.redDeep),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.redDeep, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            _Legend(color: p.warning, label: 'Restaurant'),
            _Legend(color: p.red, label: 'Rider'),
            _Legend(color: p.success, label: 'Delivery address'),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: p.inkSoft, fontSize: 12)),
      ],
    );
  }
}
