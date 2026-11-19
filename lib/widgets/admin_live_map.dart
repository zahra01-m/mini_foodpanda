import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/order_model.dart';
import '../models/restaurant_model.dart';
import '../providers/location_provider.dart';
import 'map_unavailable.dart';

/// Admin dashboard map: every in-progress order's drop-off point plus the
/// live position of each rider currently delivering — real Google Maps
/// SDK, same as the customer/rider tracking map.
class AdminLiveMap extends ConsumerStatefulWidget {
  final List<FoodOrder> orders;
  const AdminLiveMap({super.key, required this.orders});

  @override
  ConsumerState<AdminLiveMap> createState() => _AdminLiveMapState();
}

class _AdminLiveMapState extends ConsumerState<AdminLiveMap> {
  GoogleMapController? _controller;
  int _lastFitSignature = -1;

  void _fitIfNeeded(List<LatLng> points) {
    if (points.length < 2 || _controller == null) return;
    final signature = Object.hashAll(points.map((p) => Object.hash(p.latitude, p.longitude)));
    if (signature == _lastFitSignature) return;
    _lastFitSignature = signature;
    final south = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final north = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final west = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final east = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east)),
        48,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!mapsAvailable) return const MapUnavailable(height: 220);
    final active = widget.orders
        .where((o) => o.status == OrderStatus.preparing || o.status == OrderStatus.outForDelivery)
        .toList();
    final locations = ref.watch(allRiderLocationsProvider).valueOrNull ?? const [];
    final activeRiderIds = active.map((o) => o.riderId).whereType<String>().toSet();

    final dropOffs = active.map((o) => LatLng(o.deliveryLat, o.deliveryLng)).toList();
    final riders = locations
        .where((l) => activeRiderIds.contains(l.riderId))
        .map((l) => LatLng(l.lat, l.lng))
        .toList();
    final all = [...dropOffs, ...riders];

    WidgetsBinding.instance.addPostFrameCallback((_) => _fitIfNeeded(all));

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(Restaurant.defaultLat, Restaurant.defaultLng),
            zoom: 12,
          ),
          onMapCreated: (controller) {
            _controller = controller;
            WidgetsBinding.instance.addPostFrameCallback((_) => _fitIfNeeded(all));
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          markers: {
            for (final p in dropOffs)
              Marker(
                markerId: MarkerId('drop-${p.latitude}-${p.longitude}'),
                position: p,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              ),
            for (final p in riders)
              Marker(
                markerId: MarkerId('rider-${p.latitude}-${p.longitude}'),
                position: p,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
