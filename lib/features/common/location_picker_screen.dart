import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:farmconnect/all.dart';

/// Full-screen map. Tap anywhere to drop the pin, then confirm. Pops a LatLng.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});
  final LatLng? initial;
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _ctrl = MapController();
  LatLng? _picked;
  late LatLng _start;
  bool _mapReady = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _start = widget.initial ?? const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
    _picked = widget.initial;
    if (widget.initial == null) _useMyLocation(silent: true);
  }

  Future<void> _useMyLocation({bool silent = false}) async {
    final pos = await LocationService.current();
    if (pos == null) {
      if (!silent && mounted) showMsg(context, 'Could not get your location. Tap the map instead.');
      return;
    }
    final p = LatLng(pos.latitude, pos.longitude);
    if (!mounted) return;
    setState(() => _picked = p);
    if (_mapReady) _ctrl.move(p, 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose location')),
      body: Stack(children: [
        FlutterMap(
          mapController: _ctrl,
          options: MapOptions(
            initialCenter: _start,
            initialZoom: 14,
            onMapReady: () => _mapReady = true,
            onTap: (_, p) => setState(() => _picked = p),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.farmconnect.app',
              maxZoom: 19,
            ),
            if (_picked != null)
              MarkerLayer(markers: [
                Marker(
                  point: _picked!,
                  width: 48,
                  height: 48,
                  child: const Icon(Icons.location_pin, size: 44, color: AppColors.primary),
                ),
              ]),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 110,
          child: FloatingActionButton.small(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            onPressed: _useMyLocation,
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: SafeArea(
            child: PrimaryButton(
              label: _picked == null ? 'Tap the map to drop a pin' : 'Confirm this location',
              icon: Icons.check_rounded,
              onPressed: _picked == null ? null : () => context.pop(_picked),
            ),
          ),
        ),
      ]),
    );
  }
}
